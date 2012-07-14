//
//  QuickBrowsersContainerController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickBrowsersContainerController.h"

#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"
#import "ACProject.h"

#import "QuickFileBrowserController.h"
#import "QuickBookmarkBrowserController.h"
#import "QuickProjectInfoController.h"
#import "QuickFolderInfoController.h"
#import "QuickFileInfoController.h"
#import "QuickTOCController.h"

@implementation QuickBrowsersContainerController

+ (id)defaultQuickBrowsersContainerControllerForContentController:(UIViewController *)contentController {
  static QuickBrowsersContainerController *_commonController = nil;
  static QuickBrowsersContainerController *_projectController = nil;
  static QuickBrowsersContainerController *_folderController = nil;
  static QuickBrowsersContainerController *_fileController = nil;
  
  if ([contentController.artCodeTab.currentURL isArtCodeProjectBookmarksList]) {
    if (!_commonController) {
      _commonController = [[QuickBrowsersContainerController alloc] init];
      _commonController.contentController = contentController;
      [_commonController setViewControllers:[NSArray arrayWithObjects:[QuickFileBrowserController new], [QuickBookmarkBrowserController new], nil] animated:NO];
    } else {
      _commonController.contentController = contentController;
    }
    return _commonController;
  }
  else
  {
    switch (contentController.artCodeTab.currentURL.artCodeType) {
      case ArtCodeLocationTypeProject:
        if (!_projectController)
        {
          _projectController = [[QuickBrowsersContainerController alloc] init];
          _projectController.contentController = contentController;
          [_projectController setViewControllers:[NSArray arrayWithObjects:[QuickProjectInfoController new], [QuickFileBrowserController new], [QuickBookmarkBrowserController new], nil] animated:NO];
        }
        else
        {
          _projectController.contentController = contentController;
        }
        return _projectController;
        
      case ArtCodeLocationTypeDirectory:
        if (!_folderController)
        {
          _folderController = [[QuickBrowsersContainerController alloc] init];
          _folderController.contentController = contentController;
          [_folderController setViewControllers:[NSArray arrayWithObjects:[QuickFolderInfoController new], [QuickFileBrowserController new], [QuickBookmarkBrowserController new], nil] animated:NO];
        }
        else
        {
          _folderController.contentController = contentController;
        }
        return _folderController;
        
      case ArtCodeLocationTypeTextFile:
        if (!_fileController)
        {
          _fileController = [[QuickBrowsersContainerController alloc] init];
          _fileController.contentController = contentController;
          [_fileController setViewControllers:[NSArray arrayWithObjects:[QuickFileInfoController new], [QuickTOCController new], [QuickFileBrowserController new], [QuickBookmarkBrowserController new], nil] animated:NO];
        }
        else
        {
          _fileController.contentController = contentController;
        }
        return _fileController;
        
      default:
        ASSERT(NO); // Not handled type
        break;
    }
  }
  return nil;
}

- (id)init
{
  self = [super initWithNibName:nil bundle:nil];
  if (!self)
    return nil;
  self.contentSizeForViewInPopover = CGSizeMake(500, 500);
  return self;
}

#pragma mark - Properties

@synthesize contentController, openingButton;

- (void)setContentController:(UIViewController *)value
{
  if (value == contentController)
    return;
  contentController = value;
  self.artCodeTab = contentController.artCodeTab;
}

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