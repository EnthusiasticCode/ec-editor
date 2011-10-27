//
//  ACBottomTabBarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSingleProjectBrowsersController.h"
#import "ACTab.h"

#import "ACFileTableController.h"

@implementation ACSingleProjectBrowsersController

#pragma mark - Properties

@synthesize tab;

- (NSArray *)toolbarItems
{
    return self.selectedViewController.toolbarItems;
}

- (void)setToolbarItems:(NSArray *)toolbarItems
{
    self.selectedViewController.toolbarItems = toolbarItems;
}

+ (NSSet *)keyPathsForValuesAffectingToolbarItems
{
    return [NSSet setWithObject:@"selectedViewController.toolbarItems"];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Opening Browser

- (UIViewController *)_viewControllerWithClass:(Class)class
{
    for (UIViewController *controller in self.viewControllers) {
        if ([controller isKindOfClass:class])
            return controller;
    }
    return nil;
}

- (void)openFileBrowserWithURL:(NSURL *)url
{
    ACFileTableController *tableBrowser = (ACFileTableController *)[self _viewControllerWithClass:[ACFileTableController class]];
    if (!tableBrowser)
        return;
    
    tableBrowser.directory = url;
    tableBrowser.tab = tab;
    
    self.selectedViewController = tableBrowser;
}

@end
