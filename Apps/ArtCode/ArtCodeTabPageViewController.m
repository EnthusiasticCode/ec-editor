//
//  ArtCodeTabPageViewController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTabPageViewController.h"
#import "TabBar.h"
#import "ArtCodeTab.h"
#import "SingleTabController.h"

@interface ArtCodeTabPageViewController () <TabPageViewControllerDataSource, TabBarDelegate>

@end

@implementation ArtCodeTabPageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
  for (ArtCodeTab *tab in [ArtCodeTab allTabs]) {
    [self.tabBar addTabWithTitle:tab.currentURL.lastPathComponent animated:NO];
  }
}

#pragma mark - TabPage data source

- (UIViewController *)tabPageViewController:(TabPageViewController *)tabPageController viewControllerForTabAtIndex:(NSUInteger)tabIndex {
  // Get the corresponding ArtCodeTab
  ArtCodeTab *artCodeTab = [[ArtCodeTab allTabs] objectAtIndex:tabIndex];
  
  // Search in controllers already presents as child
  for (SingleTabController *controller in self.childViewControllers) {
    if (controller.artCodeTab == artCodeTab) {
      return controller;
    }
  }
  
  // Generate a new controller
  SingleTabController *singleTabController = [SingleTabController new];
  singleTabController.artCodeTab = artCodeTab;
  
  // Attach controller's title to tab button
  UIButton *tabButton = [self.tabBar.tabControls objectAtIndex:tabIndex];
  // TODO
  
  return singleTabController;
}

#pragma mark - TabBar delegate

@end
