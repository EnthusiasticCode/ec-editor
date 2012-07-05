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

- (void)_addChildViewControllerForTabAtIndex:(NSUInteger)tabIndex;
- (void)_removeChildViewControllerForTabAtIndex:(NSUInteger)tabIndex;
- (void)_setSelctedChildViewControllerForTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

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
    NSInteger count = [tuple.second unsignedIntegerValue];
    NSInteger currentCount = this.childViewControllers.count;
    NSInteger countDiff = count - currentCount;
    if (countDiff > 0) {
      // Inserting new tabs
      for (NSInteger i = 0; i < countDiff; ++i) {
        [this _addChildViewControllerForTabAtIndex:count + i];
      }
    } else if (countDiff < 0) {
      // Remove tabs
      for (NSInteger i = countDiff; i < 0; ++i) {
        [this _removeChildViewControllerForTabAtIndex:currentCount + i];
      }
    }

    // Set selection
    [this _setSelctedChildViewControllerForTabAtIndex:[tuple.first unsignedIntegerValue] animated:YES];
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
  
  [self _setSelctedChildViewControllerForTabAtIndex:self.tabBar.selectedTabIndex animated:NO];
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

- (void)_addChildViewControllerForTabAtIndex:(NSUInteger)tabIndex {
  ASSERT(self.dataSource);
  ASSERT(tabIndex != NSNotFound);
  
  // Get the child controller to show
  UIViewController *childController = [self.dataSource tabPageViewController:self viewControllerForTabAtIndex:tabIndex];
  if (!childController || [self.childViewControllers containsObject:childController])
    return;
  
  // Add the child controller
  [self addChildViewController:childController];
  
  // Inform controller of insertion
  [childController didMoveToParentViewController:self];
}

- (void)_removeChildViewControllerForTabAtIndex:(NSUInteger)tabIndex {
  ASSERT(self.dataSource);
  ASSERT(tabIndex != NSNotFound);
  
  UIViewController *childController = [self.dataSource tabPageViewController:self viewControllerForTabAtIndex:tabIndex];
  if (!childController || ![self.childViewControllers containsObject:childController])
    return;
  
  // Remove child view from container
  [childController willMoveToParentViewController:nil];
  if (childController.isViewLoaded) {
    [childController.view removeFromSuperview];
  }
  [childController removeFromParentViewController];
}

- (void)_setSelctedChildViewControllerForTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated {
  ASSERT(self.dataSource);
  
  if (tabIndex == NSNotFound)
    return;
  
  // Retrieve the child controller
  UIViewController *childController = [self.dataSource tabPageViewController:self viewControllerForTabAtIndex:tabIndex];
  if (!childController || ![self.childViewControllers containsObject:childController])
    return;
  
  // Modify animation status if there is no other view to transition to
  if (_childContainerView.subviews.count == 0) {
    animated = NO;
  }
  
  // Setup the child controller view if neccessary
  if (childController.view.superview != _childContainerView) {
    [childController.view removeFromSuperview];
    [_childContainerView addSubview:childController.view];
    [self _layoutSubviews];
  } else {
    [_childContainerView bringSubviewToFront:childController.view];
  }
  childController.view.alpha = 0;
  
  // Animate
  [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
    childController.view.alpha = 1;
  } completion:^(BOOL finished) {
    // Remove unused views and inform controllers
    [childController didMoveToParentViewController:self];
    for (UIView *view in _childContainerView.subviews) {
      if (view != childController.view) {
        [view removeFromSuperview];
      }
    }
  }]; 
}

@end
