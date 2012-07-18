//
//  NewRemoteViewController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewRemoteViewController.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "ArtCodeRemote.h"

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

- (void)_createAction:(id)sender
{
  NSMutableString *remoteURLString = [NSMutableString new];
  switch (self.remoteType.selectedSegmentIndex) {
    case 0:
      [remoteURLString appendString:@"ftp://"];
      break;
      
    case 1:
      [remoteURLString appendString:@"ssh://"];
      break;
      
    case 2:
      [remoteURLString appendString:@"http://"];
      break;
  }
  if ([self.remoteUser.text length])
    [remoteURLString appendFormat:@"%@@", self.remoteUser.text];
  [remoteURLString appendString:self.remoteHost.text];
  if ([self.remotePort.text length])
    [remoteURLString appendFormat:@":%d", [self.remotePort.text integerValue]];
  
  ArtCodeRemote *remote = [[ArtCodeRemote alloc] init];
  remote.name = self.remoteName.text;
  remote.url = [NSURL URLWithString:remoteURLString];
  
  [self.artCodeTab.currentLocation.project addRemotesObject:remote];
  
  if (remote)
  {
//    if ([self.remotePassword.text length])
//      remote.password = self.remotePassword.text;
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Remote added" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }
  else
  {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Error adding new remote" imageNamed:BezelAlertForbiddenIcon displayImmediatly:NO];
  }
  
  [self.presentingPopoverController dismissPopoverAnimated:YES];
}

@end
