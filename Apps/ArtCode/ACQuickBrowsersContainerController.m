//
//  ACQuickBrowsersContainerController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACQuickBrowsersContainerController.h"

#import "ACTab.h"
#import "ACQuickFileBrowserController.h"
#import "ACQuickBookmarkBrowserController.h"

@implementation ACQuickBrowsersContainerController

+ (id)quickBrowsersContainerControllerForTab:(ACTab *)tab
{
    ACQuickBrowsersContainerController *result = [ACQuickBrowsersContainerController new];
    result.tab = tab;
    result.contentSizeForViewInPopover = CGSizeMake(500, 500);
    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[tab.currentURL path] isDirectory:&isDirectory];
    if (isDirectory)
    {
        [result setViewControllers:[NSArray arrayWithObjects:[ACQuickFileBrowserController new], [ACQuickBookmarkBrowserController new], nil] animated:NO];
    }
    else
    {
        // TODO
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


@implementation UIViewController (ACQuickBrowsersContainerController)

- (ACQuickBrowsersContainerController *)quickBrowsersContainerController
{
    return (ACQuickBrowsersContainerController *)self.parentViewController;
}

@end