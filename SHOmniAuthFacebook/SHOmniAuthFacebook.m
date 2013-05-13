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


#import "AFOAuth1Client.h"

#define NSNullIfNil(v) (v ? v : [NSNull null])



@interface SHOmniAuthFacebook ()
+(void)updateAccount:(ACAccount *)theAccount withCompleteBlock:(SHOmniAuthAccountResponseHandler)completeBlock;
+(void)performLoginForNewAccount:(SHOmniAuthAccountResponseHandler)completionBlock;
+(NSMutableDictionary *)authHashWithResponse:(NSDictionary *)theResponse;

@end

@implementation SHOmniAuthFacebook


+(void)performLoginWithListOfAccounts:(SHOmniAuthAccountsListHandler)accountPickerBlock
                           onComplete:(SHOmniAuthAccountResponseHandler)completionBlock; {
  SHAccountStore * store = [[SHAccountStore alloc] init];
  SHAccountType  * type = [store accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  
  accountPickerBlock([store accountsWithAccountType:type], ^(id<account> theChosenAccount) {
    
    if(theChosenAccount == nil) [self performLoginForNewAccount:completionBlock];
    else [SHOmniAuthFacebook updateAccount:(SHAccount *)theChosenAccount withCompleteBlock:completionBlock];
    
  });
  
  
  
  
  
}


+(BOOL)hasLocalAccountOnDevice; {
  SHAccountStore * store = [[SHAccountStore alloc] init];
  SHAccountType  * type  = [store accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  return [store accountsWithAccountType:type].count > 0;
}
+(NSString *)provider; {
  return self.description;
}

+(NSString *)accountTypeIdentifier; {
  return self.description;
}

+(NSString *)serviceType; {
  return self.description;
}

+(NSString *)description; {
  return NSStringFromClass(self.class);
}

+(void)performLoginForNewAccount:(SHOmniAuthAccountResponseHandler)completionBlock;{
  SHAccountStore * store    = [[SHAccountStore alloc] init];
  SHAccountType  * type     = [store accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  SHAccount      * account  = [[SHAccount alloc] initWithAccountType:type];
  AFOAuth1Client *  client = [[AFOAuth1Client alloc]
                                              initWithBaseURL:
                                              [NSURL URLWithString:@"http://www.flickr.com/services"]
                                              key:[SHOmniAuth providerValue:SHOmniAuthProviderValueKey forProvider:self.provider]
                                              secret:[SHOmniAuth providerValue:SHOmniAuthProviderValueSecret forProvider:self.provider]
                                              ];
  
  [client authorizeUsingOAuthWithRequestTokenPath:@"oauth/request_token"
                                    userAuthorizationPath:@"oauth/authorize"
                                              callbackURL:[NSURL URLWithString:
                                                           [SHOmniAuth providerValue:SHOmniAuthProviderValueCallbackUrl
                                                                         forProvider:self.provider]]
                                          accessTokenPath:@"oauth/access_token"
                                             accessMethod:@"POST"
                                                    scope:[SHOmniAuth providerValue:SHOmniAuthProviderValueScope
                                                                        forProvider:self.provider]
                                                  success:^(AFOAuth1Token *accessToken, id responseObject) {
                                                    
                                                    
                                                    NSString     * response      = nil;
                                                    if(responseObject)
                                                      response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                                                    NSDictionary * responseDict = nil;
                                                    if(response)
                                                      responseDict = [NSURL ab_parseURLQueryString:response];

                                                    

                                                    SHAccountCredential * credential = [[SHAccountCredential alloc]
                                                                                   initWithOAuthToken:accessToken.key
                                                                                   tokenSecret:accessToken.secret];
                                               
                                                    account.credential = credential;
                                                    account.username = responseDict[@"username"];
                                                    account.identifier = responseDict[@"user_nsid"];
                                                    
                                               [SHOmniAuthFacebook updateAccount:account withCompleteBlock:completionBlock];
                                               
                                             } failure:^(NSError *error) {
                                               completionBlock(nil, nil, error, NO);
                                             }];
  
}


+(void)updateAccount:(SHAccount *)theAccount withCompleteBlock:(SHOmniAuthAccountResponseHandler)completeBlock; {
  SHAccountStore * accountStore = [[SHAccountStore alloc] init];
  SHAccountType  * accountType  = [accountStore accountTypeWithAccountTypeIdentifier:self.accountTypeIdentifier];
  [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
    if(granted) {
      
      
      
      NSString * fields = theAccount.identifier;
      NSString * urlString = [NSString stringWithFormat:@"https://www.flickr.com/services/rest/?format=json&method=flickr.people.getInfo&nojsoncallback=1&user_id=%@", fields];

      SHRequest * request=  [SHRequest requestForServiceType:theAccount.accountType.identifier requestMethod:SHRequestMethodGET URL:[NSURL URLWithString:urlString] parameters:nil];
      request.account = (id<account>)theAccount;
      [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSDictionary * response = nil;
        if(responseData) response =  [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        
        if(error || [response[@"status"] integerValue] == 400 ){
          dispatch_async(dispatch_get_main_queue(), ^{ completeBlock(nil, nil, error, NO); });
          return;
        }
        
        
                
        [accountStore saveAccount:theAccount withCompletionHandler:^(BOOL success, NSError *error) {
          NSMutableDictionary * fullResponse = response.mutableCopy;
          id<accountPrivate> privateAccount = (id<accountPrivate>)theAccount;
          fullResponse[@"oauth_token"]        = privateAccount.credential.token;
          fullResponse[@"oauth_token_secret"] = privateAccount.credential.secret;

          dispatch_async(dispatch_get_main_queue(), ^{ completeBlock((id<account>)theAccount, [self authHashWithResponse:fullResponse], error, success); });
        }];
        
      }];
      
    }
    else
      dispatch_async(dispatch_get_main_queue(), ^{ completeBlock((id<account>)theAccount, nil, error, granted); });
    
  }];
  
}

+(NSMutableDictionary *)authHashWithResponse:(NSDictionary *)theResponse; {
  NSString * name      = theResponse[@"person"][@"realname"][@"_content"];
  NSArray  * names     = [name componentsSeparatedByString:@" "];
  NSString * firstName = nil;
  NSString * lastName  = nil;
  if(names.count > 0)
    firstName = names[0];
  if(names.count > 1)
    lastName = names[1];
  if(names.count > 2)
    lastName = names[names.count-1];
  
    
    
  NSMutableDictionary * omniAuthHash = @{@"auth" :
                                  @{@"credentials" : @{@"secret" : NSNullIfNil(theResponse[@"oauth_token_secret"]),
                                                     @"token"  : NSNullIfNil(theResponse[@"oauth_token"])
                                                     }.mutableCopy,
                                  
                                  @"info" : @{@"description"  : NSNullIfNil(theResponse[@"person"][@"description"][@"_content"]),
                                              @"email"        : NSNullIfNil(theResponse[@"email"]),
                                              @"first_name"   : NSNullIfNil(firstName),
                                              @"last_name"    : NSNullIfNil(lastName),
                                              @"headline"     : NSNullIfNil(theResponse[@"headline"]),
                                              @"industry"     : NSNullIfNil(theResponse[@"industry"]),
                                              @"image"        : NSNullIfNil(theResponse[@"profile_image_url"]),
                                              @"name"         : NSNullIfNil(name),
                                              @"urls"         : @{@"public_profile" : NSNullIfNil(theResponse[@"person"][@"profileurl"][@"_content"])
                                                                  }.mutableCopy,
                                              
                                              }.mutableCopy,
                                  @"provider" : @"flickr",
                                  @"uid"      : NSNullIfNil(theResponse[@"person"][@"nsid"]),
                                  @"raw_info" : NSNullIfNil(theResponse)
                                    }.mutableCopy,
                                  @"email"    : NSNullIfNil(theResponse[@"email"]),
                                  }.mutableCopy;
  
  
  return omniAuthHash;
  
}


@end
