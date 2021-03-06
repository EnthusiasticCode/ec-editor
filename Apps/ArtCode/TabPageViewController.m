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

- (void)_populateChildViewControllersUpToCount:(NSUInteger)tabsCount;
- (void)_setSelectedChildViewControllerForTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

@end

@implementation TabPageViewController {
  UIView *_childContainerView;
}

#pragma mark - Properties

- (void)setTabBarVisible:(BOOL)tabBarVisible {
  [self setTabBarVisible:tabBarVisible animated:NO];
}

- (void)setTabBarVisible:(BOOL)tabBarVisible animated:(BOOL)animated {
  if (tabBarVisible == _tabBarVisible)
    return;
  
  [self willChangeValueForKey:@"tabBarVisible"];
  _tabBarVisible = tabBarVisible;
  [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
    [self _layoutSubviews];
  }];
  [self didChangeValueForKey:@"tabBarVisible"];
}

#pragma mark - Controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  
  _tabBarVisible = YES;
    
  return self;
}

#pragma mark - View lifecycle

- (void)loadView {
  [super loadView];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  _tabBar = [[TabBar alloc] init];
  _tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
  [self.view addSubview:_tabBar];
  
  _childContainerView = [[UIView alloc] init];
  _childContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:_childContainerView];
  
  [self _layoutSubviews];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // RAC
  __weak TabPageViewController *this = self;
	
	[[RACSignal combineLatest:@[RACAble(self.tabBar.selectedTabIndex), RACAble(self.tabBar.tabsCount)]] subscribeNext:^(RACTuple *tuple) {
    [this _populateChildViewControllersUpToCount:[tuple.second unsignedIntegerValue]];
    [this _setSelectedChildViewControllerForTabAtIndex:[tuple.first unsignedIntegerValue] animated:NO];
  }];;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self _setSelectedChildViewControllerForTabAtIndex:self.tabBar.selectedTabIndex animated:NO];
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

- (void)_populateChildViewControllersUpToCount:(NSUInteger)tabsCount {
  ASSERT(self.dataSource);
  
  // Fetch all view controllers that should become child
  NSMutableArray *childControllers = [NSMutableArray arrayWithCapacity:tabsCount];
  for (NSUInteger i = 0; i < tabsCount; ++i) {
    [childControllers addObject:[self.dataSource tabPageViewController:self viewControllerForTabAtIndex:i]];
  }
  
  // Remove not needed view controllers
  NSArray *originalChildControllers = self.childViewControllers;
  for (UIViewController *controller in originalChildControllers) {
    if (![childControllers containsObject:controller]) {
      // If a controller is in the childrens but should not, it will get removed
      [controller willMoveToParentViewController:nil];
      if (controller.isViewLoaded) {
        // Fade out the view if it's loaded
        [UIView animateWithDuration:0.2 animations:^{
          controller.view.alpha = 0;
        } completion:^(BOOL finished) {
          controller.view.alpha = 1;
          [controller.view removeFromSuperview];
          [controller removeFromParentViewController];
        }];
      } else {
        [controller removeFromParentViewController];
      }
    }
  }
  
  // Add missing controlelrs
  originalChildControllers = self.childViewControllers;
  for (UIViewController *controller in childControllers) {
    if (![originalChildControllers containsObject:controller]) {
      [self addChildViewController:controller];
      [controller didMoveToParentViewController:self];
    }
  }
}

- (void)_setSelectedChildViewControllerForTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated {
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
    // If the child controller's view is in the container, it's already the selected tab
    return;
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

#pragma mark

@implementation UIViewController (TabPageViewController)

- (TabPageViewController *)tabPageViewController {
  ASSERT([self.parentViewController isKindOfClass:TabPageViewController.class]);
  return (TabPageViewController *)self.parentViewController;
}

@end
