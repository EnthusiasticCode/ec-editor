//
//  RemoteOptionsViewController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteOptionsViewController.h"

@implementation RemoteOptionsViewController

@synthesize remoteName;
@synthesize remoteType;
@synthesize remoteHost;
@synthesize remotePort;
@synthesize remoteUser;
@synthesize remotePassword;

- (id)init
{
    self = [super initWithNibName:@"RemoteOptions" bundle:nil];
    self.contentSizeForViewInPopover = CGSizeMake(400, 269);
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (void)viewDidUnload
{
    [self setRemoteType:nil];
    [self setRemoteHost:nil];
    [self setRemotePort:nil];
    [self setRemoteUser:nil];
    [self setRemotePassword:nil];
    [self setRemoteName:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
