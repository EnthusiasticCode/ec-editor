//
//  TabBar.h
//  ACUI
//
//  Created by Nicola Peduzzi on 22/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TabBar;

@protocol TabBarDelegate <UIScrollViewDelegate>
@optional

- (BOOL)tabBar:(TabBar *)tabBar willSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(TabBar *)tabBar didSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;

- (BOOL)tabBar:(TabBar *)tabBar willAddTabAtIndex:(NSUInteger)tabIndex;
- (void)tabBar:(TabBar *)tabBar didAddTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

- (BOOL)tabBar:(TabBar *)tabBar willRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(TabBar *)tabBar didRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;

- (BOOL)tabBar:(TabBar *)tabBar willMoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex;
- (void)tabBar:(TabBar *)tabBar didMoveTabControl:(UIControl *)tabControl fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end

/// TabBar present a view with buttons to choose tab as well as options to 
/// create more tabs and closing the one existing. Tabs can be scrolled outside
/// the view bounds and reorganized.
@interface TabBar : UIView

@property (nonatomic, weak) id<TabBarDelegate> delegate;

/// Access to the gesture recognizer used to move tabs.
@property (nonatomic, readonly, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

#pragma mark Configuring a Tab Bar

@property (nonatomic) CGSize tabControlSize;
@property (nonatomic) UIEdgeInsets tabControlInsets;

/// An array containing controls to add at the right of the tab bar.
@property (nonatomic, copy) NSArray *additionalControls;
@property (nonatomic) CGSize additionalControlSize;
@property (nonatomic) UIEdgeInsets additionalControlInsets;

#pragma mark Managing Tabs

@property (nonatomic, readonly, copy) NSArray *tabControls;

/// The index of the currently selected tab. This can return NSNotFound if there is no selected tab.
@property (nonatomic) NSUInteger selectedTabIndex;

/// This property reflect the tabControls.count but it's observable.
@property (nonatomic, readonly) NSUInteger tabsCount;

- (void)setSelectedTabIndex:(NSUInteger)tabIndex animated:(BOOL)animated;
- (void)addTabWithTitle:(NSString *)title animated:(BOOL)animated;
- (void)removeTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated;
- (void)moveTabAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated;

- (void)setTitle:(NSString *)title forTabAtIndex:(NSUInteger)tabIndex;

@end

/// Button used as a tab element. This class is intended to be used as an appearance selector.
@interface TabBarButton : UIButton
@end

/// Button used as close button inside a tab button. This class is intended to be used as an appearance selector.
@interface TabBarButtonCloseButton : UIButton
@end
