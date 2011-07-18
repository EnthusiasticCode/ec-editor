//
//  ACTabController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTabBar.h"
#import "ACURLTarget.h"

/// Use this value to identify the current tab in various APIs.
enum {ACTabCurrent = NSIntegerMax};

@class ACTabController;
@class ECSwipeGestureRecognizer;


@protocol ACTabControllerDelegate <NSObject>
@required

- (UIViewController<ACURLTarget> *)tabController:(ACTabController *)tabController viewControllerForURL:(NSURL *)url previousViewController:(UIViewController<ACURLTarget> *)previousViewController;

@end


@interface ACTabController : UIViewController <ECTabBarDelegate>

@property (nonatomic, weak) id<ACTabControllerDelegate> delegate;

#pragma mark Controller's Views

/// A flag indicating if the tab bar can be displayed.
@property (nonatomic, getter = isTabBarEnabled) BOOL tabBarEnabled;

/// The tab bar
@property (nonatomic, strong) IBOutlet ECTabBar *tabBar;

/// The scroll view that contains all tab pages
@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;

/// The gesture recognizer used to toggle the tabbar.
@property (nonatomic, readonly, strong) ECSwipeGestureRecognizer *swipeGestureRecognizer;

#pragma mark Tab Bar Actions

/// Shows or hide the tab bar. This method can be called from a control's action.
- (void)toggleTabBar:(id)sender;

#pragma mark Tab Navigation Methods

/// An array of ACTab containing all the tabs in displaying order.
@property (nonatomic, strong, readonly) NSArray *tabs;

/// Gets or set the current tab.
@property (nonatomic) NSUInteger currentTabIndex;
- (void)setCurrentTabIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

/// Return the tab with the given title if present; nil otherwise.
- (NSUInteger)indexOfTabWithTitle:(NSString *)title;

/// Add a new tab with the given url and title. If title is nil it will be infered
/// by the URL. The delegate tabController:viewControllerForURL: method may be 
/// implemented to make this method effective.
/// Returns the created tab.
- (NSUInteger)addTabWithURL:(NSURL *)url title:(NSString *)title animated:(BOOL)animated;

/// Pushes the given URL to the specified tab's history.
- (void)pushURL:(NSURL *)url toTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

/// Moves the history point of the given tab.
- (void)setHistoryPoint:(NSUInteger *)index forTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

/// Pops the current URL from the given tab. The url is popped only if it's not 
/// the only one remaining in the tab's history.
- (void)popURLFromTabAtIndex:(NSUInteger)tabIndex;

/// Removes the tab form the controller. This method will not remove a tab if 
/// it's the last remaining.
- (void)removeTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated;

@end
