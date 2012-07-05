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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  self.dataSource = self;
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.tabBar.backgroundColor = [UIColor blackColor];
  self.tabBar.tabControlInsets = UIEdgeInsetsMake(5, 3, 0, 3);
  // TODO change child container view background to white
  
  for (ArtCodeTab *tab in [ArtCodeTab allTabs]) {
    [self.tabBar addTabWithTitle:tab.currentURL.lastPathComponent animated:NO];
  }
  // TODO get selected from persistence user defaults
  [self.tabBar setSelectedTabIndex:0];
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
  
  // RAC 
  // Attach controller's title to tab button
  UIButton *tabButton = [self.tabBar.tabControls objectAtIndex:tabIndex];
  [[[[singleTabController rac_subscribableForKeyPath:RAC_KEYPATH(singleTabController, title) onObject:singleTabController] distinctUntilChanged] injectObjectWeakly:tabButton] subscribeNext:^(RACTuple *tuple) {
    if (tuple.first != [RACTupleNil tupleNil] && tuple.second) {
      [tuple.second setTitle:tuple.first forState:UIControlStateNormal];
    }
  }];
  
  return singleTabController;
}

#pragma mark - TabBar delegate

@end
