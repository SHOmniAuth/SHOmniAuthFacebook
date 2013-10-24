//
//  SHAppDelegate.m
//  SHOmniAuthFacebookExample
//
//  Created by Seivan Heidari on 5/13/13.
//  Copyright (c) 2013 Seivan Heidari. All rights reserved.
//

#import "SHViewController.h"
#import <SHOmniAuthFacebook.h>
#import <SHActionSheetBlocks.h>
#import <SHAlertViewBlocks.h>
#import <NSArray+SHFastEnumerationProtocols.h>

@interface SHViewController ()

@end

@implementation SHViewController

-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
  [SHOmniAuthFacebook performLoginWithListOfAccounts:^(NSArray *accounts, SHOmniAuthAccountPickerHandler pickAccountBlock) {

    UIActionSheet * actionSheet = [UIActionSheet SH_actionSheetWithTitle:@"Pick Facebook account"];
    [accounts SH_each:^(id<account> account) {
      [actionSheet SH_addButtonWithTitle:account.username withBlock:^(NSInteger theButtonIndex) {
        pickAccountBlock(account);
      }];
    }];
    
    NSString * buttonTitle = nil;
    if(accounts.count > 0)
      buttonTitle = @"Add account";
    else
      buttonTitle = @"Connect with Facebook";
    
    [actionSheet SH_addButtonWithTitle:buttonTitle withBlock:^(NSInteger theButtonIndex) {
      pickAccountBlock(nil);
    }];
    
    [actionSheet showInView:self.view];

    
    
  } onComplete:^(id<account> account, id response, NSError *error, BOOL isSuccess) {
    NSLog(@"%@", response);
    [[UIAlertView SH_alertViewWithTitle:nil andMessage:[response description] buttonTitles:nil cancelTitle:@"OK" withBlock:nil] show];
  }];
}

@end
