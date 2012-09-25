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
  ArtCodeRemote *remote = [ArtCodeRemote insertInManagedObjectContext:self.artCodeTab.currentLocation.project.managedObjectContext];
  
  switch (self.remoteType.selectedSegmentIndex) {
    case 0:
      remote.scheme = @"ftp";
      break;
      
    case 1:
      remote.scheme = @"ssh";
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
  
  [[self.artCodeTab.currentLocation.project mutableOrderedSetValueForKey:@"remotes"] addObject:remote];
  
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
