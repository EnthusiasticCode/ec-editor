//
//  QuickRemoteInfoController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickRemoteInfoController.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "Keychain.h"


@implementation QuickRemoteInfoController {
    ProjectRemote *_remote;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _remote = [self.artCodeTab.currentProject remoteForURL:self.artCodeTab.currentURL];
    ECASSERT(_remote != nil);
    self.remoteName.text = _remote.name;
    self.remoteHost.text = _remote.host;
    self.remotePort.text = _remote.port ? [NSString stringWithFormat:@"%d", _remote.port] : nil;
    self.remoteTypeString = _remote.scheme;
    self.remoteUser.text = _remote.user;
    self.remotePassword.text = _remote.password;
    
    self.remoteHost.enabled = NO;
    self.remotePort.enabled = NO;
    self.remoteType.enabled = NO;
}

- (void)remoteTypeChangedAction:(id)sender
{
    _remote.scheme = self.remoteTypeString;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.remoteName && [textField.text length])
        _remote.name = textField.text;
    else if (textField == self.remoteHost && [textField.text length])
        _remote.host = textField.text;
    else if (textField == self.remotePort)
        _remote.port = [textField.text integerValue];
    else if (textField == self.remoteUser)
        _remote.user = textField.text;
    else if (textField == self.remotePassword)
        _remote.password = textField.text;
}

@end
