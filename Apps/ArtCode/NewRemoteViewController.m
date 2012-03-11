//
//  NewRemoteViewController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewRemoteViewController.h"
#import "ArtCodeTab.h"

#import "UIViewController+Utilities.h"

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
#warning FIX
    ECASSERT(NO);
    
    // TODO add check for duplicate, validate fields
//    ProjectRemote *remote = [ProjectRemote new];
//    remote.name = self.remoteName.text;
//    switch (self.remoteType.selectedSegmentIndex) {
//        case 0:
//            remote.scheme = @"ftp";
//            break;
//#warning TODO set proper schemes
//        case 1:
//            remote.scheme = @"ssh";
//            break;
//            
//        case 2:
//            remote.scheme = @"webdav";
//            break;
//    }
//    remote.host = self.remoteHost.text;
//    remote.port = [self.remotePort.text integerValue];
//    // TODO save password in keychain instead
//    remote.user = self.remoteUser.text;
//    if ([self.remotePassword.text length])
//        remote.password = self.remotePassword.text;
//    [self.artCodeTab.currentProject addRemote:remote];
//    [self.presentingPopoverController dismissPopoverAnimated:YES];
}

@end
