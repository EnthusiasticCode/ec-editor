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
  ArtCodeRemote *remote = [ArtCodeRemoteSet.defaultSet newRemote];
  
  switch (self.remoteType.selectedSegmentIndex) {
    case 0:
      remote.scheme = @"ftp";
      break;
      
    case 1:
      remote.scheme = @"sftp";
      break;
      
    case 2:
      remote.scheme = @"http";
      break;
  }
  remote.user = self.remoteUser.text;
  remote.host = self.remoteHost.text;
  if ([self.remotePort.text length]) {
    remote.portValue = [self.remotePort.text intValue];
  }
  remote.name = self.remoteName.text;
  
  if (remote)
  {
//    if ([self.remotePassword.text length])
//      remote.password = self.remotePassword.text;
    [BezelAlert.defaultBezelAlert addAlertMessageWithText:@"Remote added" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }
  else
  {
    [BezelAlert.defaultBezelAlert addAlertMessageWithText:@"Error adding new remote" imageNamed:BezelAlertForbiddenIcon displayImmediatly:NO];
  }
  
  [self.presentingPopoverController dismissPopoverAnimated:YES];
}

@end
