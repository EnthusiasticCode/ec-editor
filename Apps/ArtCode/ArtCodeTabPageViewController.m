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

- (void)_addButtonAction:(id)sender;

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
  
  // Adjust tab bar appearence
  self.tabBar.backgroundColor = [UIColor blackColor];
  self.tabBar.tabControlInsets = UIEdgeInsetsMake(5, 3, 0, 3);
  // TODO change child container view background to white
  
  // Add tab button
  UIButton *addTabButton = [UIButton new];
  [addTabButton setImage:[UIImage imageNamed:@"tabBar_TabAddButton"] forState:UIControlStateNormal];
  [addTabButton addTarget:self action:@selector(_addButtonAction:) forControlEvents:UIControlEventTouchUpInside];
  self.tabBar.additionalControls = [NSArray arrayWithObject:addTabButton];
  
  for (ArtCodeTab *tab in [ArtCodeTab allTabs]) {
    [self.tabBar addTabWithTitle:tab.currentURL.lastPathComponent animated:NO];
  }
  // Get selected tab from persisted user defaults
  [self.tabBar setSelectedTabIndex:[ArtCodeTab currentTabIndex]];
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
  __weak ArtCodeTabPageViewController *this = self;
  // Attach controller's title to tab button
  [[[[singleTabController rac_subscribableForKeyPath:RAC_KEYPATH(singleTabController, title) onObject:singleTabController] distinctUntilChanged] injectObjectWeakly:singleTabController] subscribeNext:^(RACTuple *tuple) {
    if (tuple.first != [RACTupleNil tupleNil] && tuple.second) {
      [this.tabBar setTitle:tuple.first forTabAtIndex:[tuple.second artCodeTab].tabIndex];
    }
  }];
  
  return singleTabController;
}

#pragma mark - TabBar delegate

- (BOOL)tabBar:(TabBar *)tabBar willRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex {
  ArtCodeTab *artCodeTab = [[ArtCodeTab allTabs] objectAtIndex:tabIndex];
  for (SingleTabController *controller in self.childViewControllers) {
    if (controller.artCodeTab == artCodeTab) {
      controller.contentViewController = nil;
      controller.defaultToolbar = nil;
    }
  }
  [artCodeTab remove];
  return YES;
}


#pragma mark - Private methods

- (void)_addButtonAction:(id)sender {
  SingleTabController *currentSingleTabController = (SingleTabController *)[self tabPageViewController:self viewControllerForTabAtIndex:self.tabBar.selectedTabIndex];
  
  ArtCodeTab *newTab = [ArtCodeTab duplicateTab:currentSingleTabController.artCodeTab];
  [ArtCodeTab insertTab:newTab atIndex:currentSingleTabController.artCodeTab.tabIndex + 1];

  [self.tabBar addTabWithTitle:currentSingleTabController.title animated:YES];
}

@end
