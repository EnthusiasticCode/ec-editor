//
//  ECTabBar.h
//  ACUI
//
//  Created by Nicola Peduzzi on 22/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECTabBar;

@protocol ECTabBarDelegate <UIScrollViewDelegate>
@optional

- (BOOL)tabBar:(ECTabBar *)tabBar willAddTabButton:(UIButton *)tabButton atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(ECTabBar *)tabBar didAddTabButtonAtIndex:(NSUInteger)index;

- (BOOL)tabBar:(ECTabBar *)tabBar willRemoveTabButtonAtIndex:(NSUInteger)tabIndex;
- (void)tabBar:(ECTabBar *)tabBar didRemoveTabButtonAtIndex:(NSUInteger)tabIndex;

- (BOOL)tabBar:(ECTabBar *)tabBar willSelectTabAtIndex:(NSUInteger)index;
- (void)tabBar:(ECTabBar *)tabBar didSelectTabAtIndex:(NSUInteger)index;

- (BOOL)tabBar:(ECTabBar *)tabBar willMoveTabFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end


/// ECTabBar present a view with buttons to choose tab as well as options to 
/// create more tabs and closing the one existing. Tabs can be scrolled outside
/// the view bounds and reorganized.
@interface ECTabBar : UIScrollView <UIAppearanceContainer>

@property (nonatomic, weak) id<ECTabBarDelegate> delegate;

#pragma mark Stylizing Tab Bar

@property (nonatomic) CGSize tabButtonSize;
@property (nonatomic) UIEdgeInsets buttonsInsets;
@property (nonatomic, strong) UIImage *closeTabImage;

/// An array containing controls to add at the right of the tab bar.
@property (nonatomic, copy) NSArray *additionalControls;
@property (nonatomic) CGSize additionalControlsDefaultSize;

#pragma mark Managing Tabs

@property (nonatomic, readonly) NSUInteger tabCount;
@property (nonatomic) NSUInteger selectedTabIndex;

- (void)addTabButtonWithTitle:(NSString *)title animated:(BOOL)animated;
- (void)removeTabAtIndex:(NSUInteger)index animated:(BOOL)animated;

- (UIButton *)tabAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfTab:(UIButton *)tabButton;

#pragma mark Showing and Hiding the Tab Bar

- (void)presentTabBarAnimated:(BOOL)animated;
- (void)removeFromSuperviewAnimated:(BOOL)animated;

@end
