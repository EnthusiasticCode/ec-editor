//
//  TabPageViewController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TabPageViewController.h"
#import "TabBar.h"

@interface TabPageViewController ()

- (void)_layoutSubviews;

/// Sets the visible child view controller to the one retrievend from the given tab index.
/// This methods removes other child view controllers that are not selected.
- (void)_setSelctedChildViewControllerForTabIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

@end

@implementation TabPageViewController {
  UIView *_childContainerView;
}

#pragma mark - Properties

@synthesize dataSource = _dataSource, tabBar = _tabBar, gestureRecognizers = _gestureRecognizers, tabBarVisible = _tabBarVisible;

- (void)setTabBarVisible:(BOOL)tabBarVisible {
  [self setTabBarVisible:tabBarVisible animated:NO];
}

- (void)setTabBarVisible:(BOOL)tabBarVisible animated:(BOOL)animated {
  if (tabBarVisible == _tabBarVisible)
    return;
  
  [self willChangeValueForKey:@"tabBarVisible"];
  _tabBarVisible = tabBarVisible;
  // TODO animation
  [self didChangeValueForKey:@"tabBarVisible"];
}

#pragma mark - Controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  
  // RAC
  __weak TabPageViewController *this = self;
  
  [[RACAbleSelf(self.tabBar.selectedTabIndex) merge:RACAbleSelf(self.tabBar.tabsCount)] subscribeNext:^(RACTuple *tuple) {
    [this _setSelctedChildViewControllerForTabIndex:[tuple.first unsignedIntegerValue] animated:YES];
  }];
  
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - View lifecycle

- (void)loadView {
  [super loadView];
  
  _tabBar = [[TabBar alloc] init];
  _tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
  [self.view addSubview:_tabBar];
  
  _childContainerView = [UIView new];
  _childContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:_childContainerView];
  
  [self _layoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self _setSelctedChildViewControllerForTabIndex:self.tabBar.selectedTabIndex animated:NO];
}

#pragma mark - Private methods

- (void)_layoutSubviews {
  CGRect bounds = self.view.bounds;
  
  if (_tabBarVisible) {
    _tabBar.frame = CGRectMake(0, 0, bounds.size.width, 44);
    _childContainerView.frame = CGRectMake(0, 44, bounds.size.width, bounds.size.height - 44);    
  } else {
    _tabBar.frame = CGRectMake(0, -44, bounds.size.width, 44);
    _childContainerView.frame = bounds;
  }
  
  for (UIView *view in _childContainerView.subviews) {
    view.frame = _childContainerView.bounds;
  }
}

- (void)_setSelctedChildViewControllerForTabIndex:(NSUInteger)tabIndex animated:(BOOL)animated {
  ASSERT(self.dataSource);
  
  if (tabIndex == NSNotFound)
    return;
  
  // Get the child controller to show
  UIViewController *childController = [self.dataSource tabPageViewController:self viewControllerForTabAtIndex:tabIndex];
  if (!childController || [self.childViewControllers containsObject:childController])
    return;
  
  // Remove any already present child controller
  NSArray *removableChildControllers = self.childViewControllers;
  for (UIViewController *removableChildController in removableChildControllers) {
    [removableChildController willMoveToParentViewController:nil];
  }
  
  // Add the child controller
  [self addChildViewController:childController];
  
  // Setup views for animation
  [_childContainerView addSubview:childController.view];
  [self _layoutSubviews];
  childController.view.alpha = 0;
  
  // Animate
  [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
    childController.view.alpha = 1;
  } completion:^(BOOL finished) {
    // Remove views and inform controllers
    [childController didMoveToParentViewController:self];
    for (UIViewController *removableChildController in removableChildControllers) {
      if (removableChildController.isViewLoaded) {
        [removableChildController.view removeFromSuperview];
      }
      [removableChildController removeFromParentViewController];
    }
  }];  
}

@end
