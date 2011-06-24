//
//  ECTabBar.h
//  ACUI
//
//  Created by Nicola Peduzzi on 22/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECButton.h"

@class ECTabBar;

@protocol ECTabBarDelegate <UIScrollViewDelegate>
@optional

- (BOOL)tabBar:(ECTabBar *)tabBar willAddTabButton:(ECButton *)tabButton atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(ECTabBar *)tabBar didAddTabButtonAtIndex:(NSUInteger)index;

- (BOOL)tabBar:(ECTabBar *)tabBar willSelectTabAtIndex:(NSUInteger)index;
- (void)tabBar:(ECTabBar *)tabBar didSelectTabAtIndex:(NSUInteger)index;

- (BOOL)tabBar:(ECTabBar *)tabBar willMoveTabFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end


/// ECTabBar present a view with buttons to choose tab as well as options to 
/// create more tabs and closing the one existing. Tabs can be scrolled outside
/// the view bounds and reorganized.
@interface ECTabBar : UIScrollView

@property (nonatomic, weak) id<ECTabBarDelegate> delegate;

#pragma mark Stylizing Tab Bar

@property (nonatomic) CGSize tabButtonSize;
@property (nonatomic) UIEdgeInsets tabButtonInsets;
@property (nonatomic, strong) UIImage *closeTabImage;

#pragma mark Creation of New Tabs

@property (nonatomic, strong) ECButton *buttonAddTab;

- (void)addTabButtonWithTitle:(NSString *)title animated:(BOOL)animated;

#pragma mark Managing Tabs

@property (nonatomic, readonly) NSUInteger tabCount;
@property (nonatomic) NSUInteger selectedTabIndex;

- (ECButton *)tabAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfTab:(ECButton *)tabButton;
- (void)removeTabAtIndex:(NSUInteger)index animated:(BOOL)animated;

#pragma mark Showing and Hiding the Tab Bar

- (void)presentTabBarAnimated:(BOOL)animated;
- (void)removeFromSuperviewAnimated:(BOOL)animated;

@end
