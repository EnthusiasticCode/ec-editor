//
//  ACTabNavigationController.h
//  tab
//
//  Created by Nicola Peduzzi on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTabBar.h"
#import "ACTabController.h"

@class ACTabNavigationController;
@class ECSwipeGestureRecognizer;


@protocol ACTabNavigationControllerDelegate <NSObject>
@optional

- (BOOL)tabNavigationController:(ACTabNavigationController *)tabNavigationController willChangeCurrentTabController:(ACTabController *)tabController fromTabController:(ACTabController *)previousTabController;
- (void)tabNavigationController:(ACTabNavigationController *)tabNavigationController didChangeCurrentTabController:(ACTabController *)tabController fromTabController:(ACTabController *)previousTabController;

- (BOOL)tabNavigationController:(ACTabNavigationController *)tabNavigationController willAddTabController:(ACTabController *)tabController;
- (void)tabNavigationController:(ACTabNavigationController *)tabNavigationController didAddTabController:(ACTabController *)tabController;

- (BOOL)tabNavigationController:(ACTabNavigationController *)tabNavigationController willRemoveTabController:(ACTabController *)tabController;
- (void)tabNavigationController:(ACTabNavigationController *)tabNavigationController didRemoveTabController:(ACTabController *)tabController;

@end


@interface ACTabNavigationController : UIViewController <ECTabBarDelegate, ACTabControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) id<ACTabNavigationControllerDelegate> delegate;

#pragma mark Layout

/// Define a margin between two tab pages.
@property (nonatomic) CGFloat tabPageMargin;

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

/// Called by the + button. Will duplicate the current tab.
- (IBAction)duplicateCurrentTab:(id)sender;

/// Shows or hide the tab bar. This method can be called from a control's action.
- (IBAction)toggleTabBar:(id)sender;

#pragma mark Managing Tabs

/// The array of ordered tab controllers managed by this tab navigator.
@property (nonatomic, readonly, copy) NSArray *tabControllers;

/// The current displayed tab controller.
@property (nonatomic, weak) ACTabController *currentTabController;

/// Set the current tab to the one provider if present in the tab collection.
- (void)setCurrentTabController:(ACTabController *)tabController animated:(BOOL)animated;

/// Returns the tab controller with the given position or nil if no tab controller
/// has been found.
- (ACTabController *)tabControllerAtPosition:(NSInteger)position;

#pragma mark Adding and Removing Tabs

/// Add a tab controller to the tab navigation. This method will not make it the current tab.
/// A tab controller will have it's delegate method set to the receiver.
- (void)addTabController:(ACTabController *)tabController animated:(BOOL)animated;

/// Conveniance method to add a tab with a datasouce and an URL. This method returns the 
/// added tab controller or nil if the controller could not be crated.
- (ACTabController *)addTabControllerWithDataSorce:(id<ACTabControllerDataSource>)datasource initialURL:(NSURL *)initialURL animated:(BOOL)animated;

/// Removes a tab controller from the tab navigation
- (void)removeTabController:(ACTabController *)tabController animated:(BOOL)animated;

@end
