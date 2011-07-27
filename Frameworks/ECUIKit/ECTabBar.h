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
@required

/// Create a new control to be used at tab control. This method should first try
/// to use dequeueReusableTabControlWithIdentifier: to reuse an already created control.
- (UIControl *)tabBar:(ECTabBar *)tabBar controlForTabWithTitle:(NSString *)title atIndex:(NSUInteger)tabIndex;

@optional

- (BOOL)tabBar:(ECTabBar *)tabBar willSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(ECTabBar *)tabBar didSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;

- (BOOL)tabBar:(ECTabBar *)tabBar willAddTabAtIndex:(NSUInteger)tabIndex;
- (void)tabBar:(ECTabBar *)tabBar didAddTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;

- (BOOL)tabBar:(ECTabBar *)tabBar willRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(ECTabBar *)tabBar didRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;

- (BOOL)tabBar:(ECTabBar *)tabBar willMoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(ECTabBar *)tabBar didMoveTabControl:(UIControl *)tabControl fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end

/// ECTabBar present a view with buttons to choose tab as well as options to 
/// create more tabs and closing the one existing. Tabs can be scrolled outside
/// the view bounds and reorganized.
@interface ECTabBar : UIView

@property (nonatomic, weak) id<ECTabBarDelegate> delegate;

/// Access to the gesture recognizer used to move tabs.
@property (nonatomic, readonly, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

#pragma mark Configuring a Tab Bar

@property (nonatomic) CGSize tabControlSize;
@property (nonatomic) UIEdgeInsets tabControlInsets;

/// An array containing controls to add at the right of the tab bar.
@property (nonatomic, copy) NSArray *additionalControls;
@property (nonatomic) CGSize additionalControlSize;
@property (nonatomic) UIEdgeInsets additionalControlInsets;

/// Returns a reusable tab control object located by its identifier.
- (UIControl *)dequeueReusableTabControlWithIdentifier:(NSString *)reuseIdentifier;

#pragma mark Managing Tabs

@property (nonatomic, readonly) NSArray *tabControls;
@property (nonatomic) NSUInteger selectedTabIndex;
@property (nonatomic, weak) UIControl *selectedTabControl;
- (void)setSelectedTabControl:(UIControl *)tabControl animated:(BOOL)animated;

- (UIControl *)addTabWithTitle:(NSString *)title animated:(BOOL)animated;
- (void)removeTabControl:(UIControl *)tabControl animated:(BOOL)animated;

@end
