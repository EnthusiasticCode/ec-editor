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
#import "ArtCodeTabSet.h"
#import "ArtCodeLocation.h"
#import "SingleTabController.h"

@interface ArtCodeTabPageViewController () <TabPageViewControllerDataSource, TabBarDelegate>

- (void)_addButtonAction:(id)sender;

@end

@implementation ArtCodeTabPageViewController {
  RACDisposable *_artCodeTabSetDisposable;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  self.dataSource = self;
  return self;
}

- (void)setArtCodeTabSet:(ArtCodeTabSet *)artCodeTabSet {
  if (artCodeTabSet == _artCodeTabSet)
    return;
  
  // RAC
  [_artCodeTabSetDisposable dispose];
  
  _artCodeTabSet = artCodeTabSet;
  
  _artCodeTabSetDisposable = [artCodeTabSet.objectsAdded subscribeNext:^(ArtCodeTab *tab) {
    [self.tabBar addTabWithTitle:tab.currentLocation.name animated:YES];
  }];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Adjust tab bar appearence
  self.tabBar.delegate = self;
  self.tabBar.backgroundColor = UIColor.blackColor;
  self.tabBar.tabControlInsets = UIEdgeInsetsMake(5, 3, 0, 3);
  // TODO: change child container view background to white
  
  // Add tab button
  UIButton *addTabButton = [[UIButton alloc] init];
  [addTabButton setImage:[UIImage imageNamed:@"tabBar_TabAddButton"] forState:UIControlStateNormal];
  [addTabButton addTarget:self action:@selector(_addButtonAction:) forControlEvents:UIControlEventTouchUpInside];
  self.tabBar.additionalControls = @[addTabButton];
  
  for (ArtCodeTab *tab in [self.artCodeTabSet tabs]) {
    [self.tabBar addTabWithTitle:tab.currentLocation.name animated:NO];
  }
  // Get selected tab from persisted user defaults
  [self.tabBar setSelectedTabIndex:[self.artCodeTabSet activeTabIndexValue]];
}

#pragma mark - TabPage data source

- (UIViewController *)tabPageViewController:(TabPageViewController *)tabPageController viewControllerForTabAtIndex:(NSUInteger)tabIndex {
  // Get the corresponding ArtCodeTab
  ArtCodeTab *artCodeTab = [self.artCodeTabSet tabs][tabIndex];
  
  // Search in controllers already presents as child
  for (SingleTabController *controller in self.childViewControllers) {
    if (controller.artCodeTab == artCodeTab) {
      return controller;
    }
  }
  
  // Generate a new controller
  SingleTabController *singleTabController = [[SingleTabController alloc] init];
  singleTabController.artCodeTab = artCodeTab;
  
  // RAC 
  __weak ArtCodeTabPageViewController *this = self;
  // Attach controller's title to tab button
  @weakify(singleTabController);
  [[[singleTabController rac_signalForKeyPath:@keypath(singleTabController, title) observer:singleTabController] distinctUntilChanged] subscribeNext:^(NSString *title) {
    @strongify(singleTabController);
    if (title && singleTabController && singleTabController.artCodeTab) {
      [this.tabBar setTitle:title forTabAtIndex:[singleTabController.artCodeTab.tabSet.tabs indexOfObject:singleTabController.artCodeTab]];
    }
  }];
  
  return singleTabController;
}

#pragma mark - TabBar delegate

- (void)tabBar:(TabBar *)tabBar didAddTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated {
  if (animated) {
    // Select last added tab if after an animation
    [tabBar setSelectedTabIndex:tabIndex animated:NO];
  }
}

- (BOOL)tabBar:(TabBar *)tabBar willRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex {
  // Don't close if it's the last tab
  if (tabBar.tabsCount == 1) {
    return NO;
  }
  
  // If this was the selected tab, change the selection to the closest one
  // This may not be the case if a tab closes automatically for history cleanup
  if (self.tabBar.selectedTabIndex == tabIndex) {
    [self.tabBar setSelectedTabIndex:tabIndex ? tabIndex - 1 : 1 animated:NO];
  }
  
  // Get the art code tab to remove
  ArtCodeTab *artCodeTab = [self.artCodeTabSet tabs][tabIndex];
  
  // Clear the controller state to avoid RAC problems
  for (SingleTabController *controller in self.childViewControllers) {
    if (controller.artCodeTab == artCodeTab) {
      controller.defaultToolbar = nil;
      controller.artCodeTab = nil;
      controller.contentViewController = nil;
      break;
    }
  }
  
  // Remove the tab
  artCodeTab.tabSet = nil;
  [artCodeTab.managedObjectContext deleteObject:artCodeTab];
  
  return YES;
}

- (void)tabBar:(TabBar *)tabBar didRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex {
  // Update stored selected index
  [self.artCodeTabSet setActiveTabIndexValue:tabBar.selectedTabIndex];
}

- (void)tabBar:(TabBar *)tabBar didSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex {
  [self.artCodeTabSet setActiveTabIndexValue:tabIndex];
}

- (void)tabBar:(TabBar *)tabBar didMoveTabControl:(UIControl *)tabControl fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
  [[self.artCodeTabSet mutableOrderedSetValueForKey:@"tabs"] moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] toIndex:toIndex];
  // Update stored selected index
  [self.artCodeTabSet setActiveTabIndexValue:tabBar.selectedTabIndex];
}

#pragma mark - Private methods

- (void)_addButtonAction:(id)sender {
  SingleTabController *currentSingleTabController = (SingleTabController *)[self tabPageViewController:self viewControllerForTabAtIndex:self.tabBar.selectedTabIndex];
  [self.artCodeTabSet addNewTabByDuplicatingTab:currentSingleTabController.artCodeTab];
}

@end
