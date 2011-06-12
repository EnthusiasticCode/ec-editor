//
//  RootController.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootController.h"

static const NSString *MenuControllerIdentifier = @"Menu";

@implementation RootController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setMenuController:[self.storyboard instantiateViewControllerWithIdentifier:(NSString *)MenuControllerIdentifier]];
}

@end
