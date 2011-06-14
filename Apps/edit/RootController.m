//
//  RootController.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootController.h"

static const NSString *SidebarControllerIdentifier = @"Sidebar";

@implementation RootController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setSidebarController:[self.storyboard instantiateViewControllerWithIdentifier:(NSString *)SidebarControllerIdentifier]];
}

@end
