//
//  QuickBrowsersContainerController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickBrowsersContainerController.h"

#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "QuickFileBrowserController.h"
#import "QuickBookmarkBrowserController.h"
#import "QuickProjectInfoController.h"
#import "QuickFolderInfoController.h"
#import "QuickFileInfoController.h"

@implementation QuickBrowsersContainerController

+ (id)quickBrowsersContainerControllerForTab:(ArtCodeTab *)tab
{
    QuickBrowsersContainerController *result = [QuickBrowsersContainerController new];
    result.tab = tab;
    result.contentSizeForViewInPopover = CGSizeMake(500, 500);
    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[tab.currentURL path] isDirectory:&isDirectory];
    if (isDirectory)
    {
        BOOL isProjectRoot = NO;
        [ArtCodeProject projectNameFromURL:tab.currentURL isProjectRoot:&isProjectRoot];
        [result setViewControllers:[NSArray arrayWithObjects: (isProjectRoot ? [QuickProjectInfoController new] : [QuickFolderInfoController new]), [QuickFileBrowserController new], [QuickBookmarkBrowserController new], nil] animated:NO];
    }
    else
    {
        [result setViewControllers:[NSArray arrayWithObjects: [QuickFileInfoController new], [QuickFileBrowserController new], [QuickBookmarkBrowserController new], nil] animated:NO];
    }
    return result;
}

#pragma mark - Properties

@synthesize tab, popoverController, openingButton;

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    [super setSelectedViewController:selectedViewController];
    self.navigationItem.leftBarButtonItem = selectedViewController.navigationItem.leftBarButtonItem;
    self.navigationItem.rightBarButtonItem = selectedViewController.navigationItem.rightBarButtonItem;
    self.navigationItem.title = selectedViewController.navigationItem.title;
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    [super setViewControllers:viewControllers animated:animated];
    [self setSelectedViewController:[viewControllers objectAtIndex:0]];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.openingButton setSelected:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.openingButton setSelected:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

// TODO dismiss on esc?

@end


@implementation UIViewController (QuickBrowsersContainerController)

- (QuickBrowsersContainerController *)quickBrowsersContainerController
{
    UIViewController *parentController = self.parentViewController;
    while (![parentController isKindOfClass:[QuickBrowsersContainerController class]]) {
        parentController = parentController.parentViewController;
    }
    return (QuickBrowsersContainerController *)parentController;
}

@end