//
//  RootController.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditorController.h"

static const NSString *SidebarControllerIdentifier = @"Sidebar";

@interface EditorController ()
- (void)_setup;
@end

@implementation EditorController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (void)_setup
{
    self.sidebarEdge = ECFloatingSplitViewControllerSidebarEdgeRight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setSidebarController:[self.storyboard instantiateViewControllerWithIdentifier:(NSString *)SidebarControllerIdentifier]];
}

@end
