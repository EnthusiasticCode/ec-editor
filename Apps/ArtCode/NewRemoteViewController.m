//
//  NewRemoteViewController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewRemoteViewController.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"

#import "UIViewController+Utilities.h"
#import "BezelAlert.h"
#import "NSURL+Utilities.h"
#import "RCIODirectory+ArtCode.h"

@interface NewRemoteViewController ()

- (void)_createAction:(id)sender;

@end

@implementation NewRemoteViewController

- (id)init
{
  self = [super init];
  if (!self)
    return nil;
  self.navigationItem.title = @"Create new remote";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleDone target:self action:@selector(_createAction:)];
  return self;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.remoteName becomeFirstResponder];
}

#pragma mark - Private methods

- (void)_createAction:(id)sender {
	NSString *scheme = nil;
  switch (self.remoteType.selectedSegmentIndex) {
    case 0:
      scheme = @"ftp";
      break;
      
    case 1:
      scheme = @"sftp";
      break;
      
    case 2:
      scheme = @"http";
      break;
  }
	NSURL *remoteURL = [NSURL URLWithScheme:scheme user:self.remoteUser.text host:self.remoteHost.text port:self.remotePort.text.intValue path:nil];
	NSDictionary *remote = @{ ArtCodeRemoteAttributeKeys.name: self.remoteName.text, ArtCodeRemoteAttributeKeys.url: remoteURL };
  
	[BezelAlert.defaultBezelAlert addAlertMessageWithText:@"Remote added" imageNamed:BezelAlertOkIcon displayImmediatly:NO];

  [self.presentingPopoverController dismissPopoverAnimated:YES];
}

@end
