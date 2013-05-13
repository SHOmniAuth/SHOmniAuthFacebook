//
//  SHAppDelegate.m
//  SHOmniAuthFacebookExample
//
//  Created by Seivan Heidari on 5/13/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHViewController.h"
#import "SHOmniAuthFacebook.h"
#import "UIActionSheet+BlocksKit.h"
#import "NSArray+BlocksKit.h"

@interface SHViewController ()

@end

@implementation SHViewController

-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
  [SHOmniAuthFacebook performLoginWithListOfAccounts:^(NSArray *accounts, SHOmniAuthAccountPickerHandler pickAccountBlock) { UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"Pick Facebook account"];
    [accounts each:^(id<account> account) {
      [actionSheet addButtonWithTitle:account.username handler:^{
        pickAccountBlock(account);
      }];
    }];
    
    NSString * buttonTitle = nil;
    if(accounts.count > 0)
      buttonTitle = @"Add account";
    else
      buttonTitle = @"Connect with Facebook";
    
    [actionSheet addButtonWithTitle:buttonTitle handler:^{
      pickAccountBlock(nil);
    }];
    
    [actionSheet showInView:self.view];

    
    
  } onComplete:^(id<account> account, id response, NSError *error, BOOL isSuccess) {
    NSLog(@"%@", response);
  }];
}

@end
