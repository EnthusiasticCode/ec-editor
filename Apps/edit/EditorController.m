//
//  RootController.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditorController.h"

static NSString *const SidebarControllerIdentifier = @"Sidebar";
static NSString *const FileControllerIdentifier = @"File";

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
    self.sidebarController = [self.storyboard instantiateViewControllerWithIdentifier:SidebarControllerIdentifier];
    self.mainController = [self.storyboard instantiateViewControllerWithIdentifier:FileControllerIdentifier];
}

@end
