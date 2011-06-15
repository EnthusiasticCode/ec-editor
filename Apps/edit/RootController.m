//
//  RootController.m
//  edit
//
//  Created by Uri Baghin on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootController.h"

static const NSString *NavbarIdentifier = @"Navbar";
static const NSString *ProjectsIdentifier = @"Projects";

@interface RootController ()
- (void)_setup;
@end

@implementation RootController

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
    self.sidebarEdge = ECFloatingSplitViewControllerSidebarEdgeTop;
    self.sidebarWidth = 50.0;
    self.sidebarLocked = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sidebarController = [self.storyboard instantiateViewControllerWithIdentifier:(NSString *)NavbarIdentifier];
    self.mainController = [self.storyboard instantiateViewControllerWithIdentifier:(NSString *)ProjectsIdentifier];
}

@end
