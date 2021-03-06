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

- (NSString *)remoteTypeString
{
  switch (self.remoteType.selectedSegmentIndex)
  {
    case 0:
      return @"ftp";
      
    case 1:
      return @"sftp";
      
    case 2:
      return @"http";
  }
  return nil;
}

- (IBAction)remoteTypeChangedAction:(id)sender {
}

- (void)setRemoteTypeString:(NSString *)remoteTypeString
{
  if ([remoteTypeString isEqualToString:@"ftp"])
    self.remoteType.selectedSegmentIndex = 0;
  else if ([remoteTypeString isEqualToString:@"sftp"])
    self.remoteType.selectedSegmentIndex = 1;
  else if ([remoteTypeString isEqualToString:@"http"])
    self.remoteType.selectedSegmentIndex = 2;
}

@end
