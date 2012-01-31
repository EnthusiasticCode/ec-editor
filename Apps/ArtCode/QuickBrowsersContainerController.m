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

+ (id)defaultQuickBrowsersContainerControllerForTab:(ArtCodeTab *)tab
{
    static QuickBrowsersContainerController *_projectController = nil;
    static QuickBrowsersContainerController *_folderController = nil;
    static QuickBrowsersContainerController *_fileController = nil;
    static NSArray *_commonControllers = nil;
    if (!_commonControllers)
        _commonControllers = [NSArray arrayWithObjects:[QuickFileBrowserController new], [QuickBookmarkBrowserController new], nil];
    
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[tab.currentURL path] isDirectory:&isDirectory];
    if (isDirectory)
    {
        BOOL isProjectRoot = NO;
        [ArtCodeProject projectNameFromURL:tab.currentURL isProjectRoot:&isProjectRoot];
        if (isProjectRoot)
        {
            if (!_projectController)
            {
                _projectController = [[QuickBrowsersContainerController alloc] initWithTab:tab];
                NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:[QuickProjectInfoController new]];
                [viewControllers addObjectsFromArray:_commonControllers];
                [_projectController setViewControllers:viewControllers animated:NO];
            }
            else
            {
                _projectController.tab = tab;
            }
            return _projectController;
        }
        else
        {
            if (!_folderController)
            {
                _folderController = [[QuickBrowsersContainerController alloc] initWithTab:tab];
                NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:[QuickFolderInfoController new]];
                [viewControllers addObjectsFromArray:_commonControllers];
                [_folderController setViewControllers:viewControllers animated:NO];
            }
            else
            {
                _folderController.tab = tab;
            }
            return _folderController;
        }
    }
    else
    {
        if (!_fileController)
        {
            _fileController = [[QuickBrowsersContainerController alloc] initWithTab:tab];
            NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:[QuickFileInfoController new]];
            [viewControllers addObjectsFromArray:_commonControllers];
            [_fileController setViewControllers:viewControllers animated:NO];
        }
        else
        {
            _fileController.tab = tab;
        }
        return _fileController;
    }
    return nil;
}

- (id)initWithTab:(ArtCodeTab *)tab
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self)
        return nil;
    self.tab = tab;
    self.contentSizeForViewInPopover = CGSizeMake(500, 500);
    return self;
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