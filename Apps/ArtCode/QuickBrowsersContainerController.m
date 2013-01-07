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
#import "ArtCodeProject.h"

#import "QuickFileBrowserController.h"
#import "QuickBookmarkBrowserController.h"
#import "QuickFolderInfoController.h"
#import "QuickFileInfoController.h"
#import "QuickTOCController.h"

@implementation QuickBrowsersContainerController

+ (id)defaultQuickBrowsersContainerControllerForContentController:(UIViewController *)contentController {
  
  QuickBrowsersContainerController *container = [[QuickBrowsersContainerController alloc] init];
  NSArray *quickBrowsers = nil;
  
  if (contentController.artCodeTab.currentLocation.type == ArtCodeLocationTypeBookmarksList) {
    quickBrowsers = @[[[QuickFileBrowserController alloc] init], [[QuickBookmarkBrowserController alloc] init]];
  } else {
    switch (contentController.artCodeTab.currentLocation.type) {
      case ArtCodeLocationTypeProject:
      case ArtCodeLocationTypeDirectory:
        quickBrowsers = @[[[UIStoryboard storyboardWithName:@"QuickInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickFolderInfo"], [[QuickFileBrowserController alloc] init], [[QuickBookmarkBrowserController alloc] init]];
        break;
      case ArtCodeLocationTypeTextFile:
        quickBrowsers = @[[[UIStoryboard storyboardWithName:@"QuickInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickFileInfo"], [[QuickTOCController alloc] init], [[QuickFileBrowserController alloc] init], [[QuickBookmarkBrowserController alloc] init]];
        break;
      default:
        break;
    }
  }
  
  // Check that we actually have a case handling the contentController
  ASSERT(quickBrowsers);
  
  container.contentController = contentController;
  container.artCodeTab = contentController.artCodeTab;
  [container setViewControllers:quickBrowsers];
  for (UIViewController *quickBrowser in quickBrowsers) {
    quickBrowser.artCodeTab = contentController.artCodeTab;
  }
  
  return container;
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

- (void)setContentController:(UIViewController *)value
{
  if (value == _contentController)
    return;
  _contentController = value;
  self.artCodeTab = _contentController.artCodeTab;
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
  [self setSelectedViewController:viewControllers[0]];
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

// TODO: dismiss on esc?

@end


@implementation UIViewController (QuickBrowsersContainerController)

- (QuickBrowsersContainerController *)quickBrowsersContainerController
{
  ASSERT([self.parentViewController isKindOfClass:[QuickBrowsersContainerController class]]);
  return (QuickBrowsersContainerController *)self.parentViewController;
}

@end