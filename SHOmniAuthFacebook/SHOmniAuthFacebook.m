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

  
  [FBSession.activeSession closeAndClearTokenInformation];
  NSString * permission = [SHOmniAuth providerValue:SHOmniAuthProviderValueKey forProvider:self.provider];
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
      
      
      accountPickerBlock([accountStore accountsWithAccountType:accountType], ^(id<account> theChosenAccount) {
        
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
                                  

                                  if(status == FBSessionStateOpen)
                                    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                      if(error)
                                        completionBlock(nil, nil, error, NO);
                                      else {
                                        [result setObject:session.accessTokenData.accessToken forKey:@"token"];
                                        completionBlock(nil,[SHOmniAuthFacebook authHashWithResponse:result],error,YES);
                                      }
                                     
                                      
                                    }];

                                  else if (status == FBSessionStateClosed || status == FBSessionStateClosedLoginFailed || error )
                                    completionBlock(nil, nil, error, NO);

                                }];
                                  

  
}


+(void)updateAccount:(ACAccount *)theAccount withCompleteBlock:(SHOmniAuthAccountResponseHandler)completeBlock; {
  ACAccountStore * accountStore = [[ACAccountStore alloc] init];
  ACAccountType  * accountType  = [accountStore accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];

  theAccount = accountStore.accounts[0];
    [accountStore renewCredentialsForAccount:theAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
            if(renewResult == ACAccountCredentialRenewResultRenewed && error == nil) {
              [accountStore saveAccount:theAccount withCompletionHandler:^(BOOL success, NSError *error) {
                SLRequest * request = [SLRequest requestForServiceType:self.serviceType requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://graph.facebook.com/me/"]
                                                            parameters:nil];
                request.account = theAccount;
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                  NSDictionary * meHash = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                  NSLog(@"%@, %@", meHash, theAccount.credential.oauthToken);
                  
                }];

              }];
            }
            else {
            }
    }];
//  NSString * fields = theAccount.identifier;
//      NSString * urlString = [NSString stringWithFormat:@"https://www.flickr.com/services/rest/?format=json&method=flickr.people.getInfo&nojsoncallback=1&user_id=%@", fields];
//
//      SLRequest * request=  [SLRequest requestForServiceType:theAccount.accountType.identifier requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:urlString] parameters:nil];
//      request.account = (id<account>)theAccount;
//      [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//        NSDictionary * response = nil;
//        if(responseData) response =  [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
//        
//        if(error || [response[@"status"] integerValue] == 400 ){
//          dispatch_async(dispatch_get_main_queue(), ^{ completeBlock(nil, nil, error, NO); });
//          return;
//        }
//        
  
                
        [accountStore saveAccount:theAccount withCompletionHandler:^(BOOL success, NSError *error) {
//          NSMutableDictionary * fullResponse = response.mutableCopy;
          id<accountPrivate> privateAccount = (id<accountPrivate>)theAccount;
//          fullResponse[@"oauth_token"]        = privateAccount.credential.token;
//          fullResponse[@"oauth_token_secret"] = privateAccount.credential.secret;

        }];
        
//    else
//      dispatch_async(dispatch_get_main_queue(), ^{ completeBlock((id<account>)theAccount, nil, error, granted); });
  
//  }];
  
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
