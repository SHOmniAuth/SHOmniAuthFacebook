//
//  SHOmniAuthFacebook.m
//  SHOmniAuth
//
//  Created by Seivan Heidari on 5/12/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

//Class dependency
#import "SHOmniAuthFacebook.h"
#import "SHOmniAuth.h"
#import "SHOmniAuthProviderPrivates.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <FacebookSDK/FacebookSDK.h>





#define NSNullIfNil(v) (v ? v : [NSNull null])


@interface SHOmniAuthFacebook ()
+(void)updateAccount:(ACAccount *)theAccount withCompleteBlock:(SHOmniAuthAccountResponseHandler)completeBlock;
+(void)performLoginForNewAccount:(SHOmniAuthAccountResponseHandler)completionBlock;
+(NSMutableDictionary *)authHashWithResponse:(NSDictionary *)theResponse;

@end

@implementation SHOmniAuthFacebook


+(void)performLoginWithListOfAccounts:(SHOmniAuthAccountsListHandler)accountPickerBlock
                           onComplete:(SHOmniAuthAccountResponseHandler)completionBlock; {




  NSString * permission = [SHOmniAuth providerValue:SHOmniAuthProviderValueScope forProvider:self.provider];
  NSArray  * permissionList = nil;
  if(permission.length > 0)
    permissionList = [permission componentsSeparatedByString:@","];
  else
    permissionList = @[@"email"];
  NSDictionary * options = @{ACFacebookAppIdKey : [SHOmniAuth providerValue:SHOmniAuthProviderValueKey forProvider:self.provider],
                             ACFacebookPermissionsKey : permissionList,
                             ACFacebookAudienceKey : ACFacebookAudienceEveryone
                             };

  ACAccountStore * accountStore = [[ACAccountStore alloc] init];
  ACAccountType  * accountType = [accountStore accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error) {

    dispatch_async(dispatch_get_main_queue(), ^{
      accountPickerBlock([accountStore accountsWithAccountType:accountType],
                         ^(id<account> theChosenAccount) {
        ACAccount * account = (ACAccount *)theChosenAccount;
        if(theChosenAccount == nil) [self performLoginForNewAccount:completionBlock];
        else [SHOmniAuthFacebook updateAccount:(ACAccount *)account withCompleteBlock:completionBlock];
      });
    });

  }];
}


+(BOOL)hasLocalAccountOnDevice; {
  ACAccountStore * store = [[ACAccountStore alloc] init];
  ACAccountType  * type  = [store accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  return [store accountsWithAccountType:type].count > 0;
}

+(BOOL)handlesOpenUrl:(NSURL *)theUrl; {
  return [FBSession.activeSession handleOpenURL:theUrl];
}

+(NSString *)provider; {
  return ACAccountTypeIdentifierFacebook;
}

+(NSString *)accountTypeIdentifier; {
  return ACAccountTypeIdentifierFacebook;
}

+(NSString *)serviceType; {
  return SLServiceTypeFacebook;
}

+(NSString *)description; {
  return NSStringFromClass(self.class);
}

+(void)performLoginForNewAccount:(SHOmniAuthAccountResponseHandler)completionBlock;{

  [FBSession openActiveSessionWithReadPermissions:@[@"email"]
                                     allowLoginUI:YES
                                completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {

                                  if (status == FBSessionStateClosed || status == FBSessionStateClosedLoginFailed || error )
                                    completionBlock(nil, nil, error, NO);
                                  else {
                                    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                      if(error)
                                        completionBlock(nil, nil, error, NO);
                                      else {
                                        [result setObject:session.accessTokenData.accessToken forKey:@"token"];
                                        completionBlock(nil,[SHOmniAuthFacebook authHashWithResponse:result],error,YES);
                                      }

                                    }];

                                  }

                                }];



}

//Refactor this fucking monster
+(void)updateAccount:(ACAccount *)theAccount withCompleteBlock:(SHOmniAuthAccountResponseHandler)completeBlock; {
  ACAccountStore * accountStore = [[ACAccountStore alloc] init];
  ACAccountType  * accountType  = [accountStore accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];

  __block ACAccount * account = nil;
  [accountStore.accounts enumerateObjectsUsingBlock:^(ACAccount * obj, NSUInteger _, BOOL *stop) {
    if([obj.username isEqualToString:theAccount.username]) {
      account = obj;
      stop = YES;
    }
  }];
    [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
            if(renewResult == ACAccountCredentialRenewResultRenewed && error == nil) {

              [accountStore saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
                if(([error.domain isEqualToString:ACErrorDomain] && error.code ==ACErrorAccountAlreadyExists) || success || error == nil) {
                  SLRequest * request = [SLRequest requestForServiceType:self.serviceType
                                                           requestMethod:SLRequestMethodGET
                                                                     URL:[NSURL URLWithString:@"https://graph.facebook.com/me/"]
                                                              parameters:nil];
                  request.account = account;
                  [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {

                    if(error) completeBlock(((id<account>)account), nil, error, NO);
                    else {
                      NSMutableDictionary * authHash = [[NSJSONSerialization
                                                        JSONObjectWithData:responseData
                                                        options:NSJSONReadingAllowFragments
                                                        error:nil] mutableCopy];
                      authHash[@"token"] = account.credential.oauthToken;
                      completeBlock(((id<account>)account),
                                    [self authHashWithResponse:authHash],
                                    error, NO);
                    }
                  }];

                }
                else
                completeBlock(((id<account>)account), nil, error, success);
              }];

            }
            else {
              completeBlock(((id<account>)account), nil, error, NO);
            }
    }];

}

+(NSMutableDictionary *)authHashWithResponse:(NSDictionary *)theResponse; {
  NSString * name      = theResponse[@"name"];
  NSArray  * names     = [name componentsSeparatedByString:@" "];
  NSString * firstName = theResponse[@"first_name"];
  NSString * lastName  = theResponse[@"last_name"];
  if(names.count > 0 && firstName == nil)
    firstName = names[0];
  if(names.count > 1 && lastName == nil)
    lastName = names[1];
  if(names.count > 2  && lastName == nil)
    lastName = names[names.count-1];



  NSMutableDictionary * omniAuthHash = @{@"auth" :
                                  @{@"credentials" : @{@"secret" : NSNullIfNil(theResponse[@"oauth_token_secret"]),
                                                       @"token"  : NSNullIfNil(theResponse[@"token"])
                                                     }.mutableCopy,

                                  @"info" : @{@"description"  : NSNullIfNil(theResponse[@"description"]),
                                              @"email"        : NSNullIfNil(theResponse[@"email"]),
                                              @"first_name"   : NSNullIfNil(firstName),
                                              @"last_name"    : NSNullIfNil(lastName),
                                              @"headline"     : NSNullIfNil(theResponse[@"headline"]),
                                              @"industry"     : NSNullIfNil(theResponse[@"industry"]),
                                              @"image"        : NSNullIfNil(theResponse[@"profile_image_url"]),
                                              @"name"         : NSNullIfNil(name),
                                              @"urls"         : @{@"public_profile" : NSNullIfNil(theResponse[@"link"])
                                                                  }.mutableCopy,

                                              }.mutableCopy,
                                  @"provider" : @"facebook",
                                  @"uid"      : NSNullIfNil(theResponse[@"id"]),
                                  @"raw_info" : NSNullIfNil(theResponse)
                                    }.mutableCopy,
                                  @"email"    : NSNullIfNil(theResponse[@"email"]),
                                  }.mutableCopy;


  return omniAuthHash;

}


@end
