//
//  TabController.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBar.h"

@interface TabController : UIViewController <TabBarDelegate, UIScrollViewDelegate>

/// Define a margin between two tab pages.
@property (nonatomic) CGFloat tabPageMargin;

#pragma mark Managing the tab bar

@property (nonatomic, readonly, strong) TabBar *tabBar;

/// Indicates if the tab bar is visible or not.
@property (nonatomic, getter = isTabBarVisible) BOOL tabBarVisible;
- (void)setTabBarVisible:(BOOL)value animated:(BOOL)animated;

#pragma mark Managing tabs

/// The view controller currently selected.
@property (nonatomic, readonly, strong) UIViewController *selectedViewController;

/// The index in the child view controllers array of the currently selected view controller.
@property (nonatomic) NSInteger selectedViewControllerIndex;
- (void)setSelectedViewControllerIndex:(NSInteger)index animated:(BOOL)animated;

/// Add a child view controller as a tab.
- (void)addChildViewController:(UIViewController *)childController animated:(BOOL)animated;

/// Removes a tab at the given index.
- (void)removeChildViewControllerAtIndex:(NSUInteger)controllerIndex animated:(BOOL)animated;

/// Reorder tabs by moving them to the specified index.
- (void)moveChildViewControllerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated;

#pragma mark Accessing the content scroll view

@property (nonatomic, readonly, strong) UIScrollView *contentScrollView;

@end

@interface UIViewController (TabController)

- (TabController *)tabCollectionController;

@end