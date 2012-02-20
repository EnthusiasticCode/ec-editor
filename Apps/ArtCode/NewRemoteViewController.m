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
#import "UIViewController+PresentingPopoverController.h"

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
    // TODO add check for duplicate, validate fields
    ProjectRemote *remote = [ProjectRemote new];
    remote.name = self.remoteName.text;
    remote.type = self.remoteType.selectedSegmentIndex;
    remote.host = self.remoteHost.text;
    remote.port = [self.remotePort.text integerValue];
    // TODO save password in keychain instead
    remote.user = self.remoteUser.text;
    remote.password = self.remotePassword.text;
    [self.artCodeTab.currentProject addRemote:remote];
    [self.presentingPopoverController dismissPopoverAnimated:YES];
}

@end
