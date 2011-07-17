//
//  ACTabController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTabBar.h"
#import "ACNavigable.h"

@class ACTabController;
@class ECSwipeGestureRecognizer;

@protocol ACTabControllerDelegate <NSObject>
@required

/// When implemented, return a view controller that can handle the given URL.
/// This method should chech if the current view controller is already able to
/// open the given URL. If it is, that controller should be returned or a transition
/// will be performed.
- (UIViewController<ACNavigable> *)tabController:(ACTabController *)tabController viewControllerForURL:(NSURL *)url;

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

- (void)toggleTabBar:(id)sender;
- (void)closeTabButtonAction:(id)sender;

#pragma mark Tab Navigation Methods

/// Gets or set the current tab using it's title.
@property (nonatomic, weak) NSString *currentTab;

/// Retrieve the titles of all tabs.
@property (nonatomic, readonly) NSArray *tabTitles;

/// Add a new tab with the given url and title. If title is nil it will be infered
/// by the URL. The delegate tabController:viewControllerForURL: method may be 
/// implemented to make this method effective.
- (void)addTabWithURL:(NSURL *)url title:(NSString *)title animated:(BOOL)animated;

/// Pushes the given URL to the specified tab's history. If tab tile is nil, the
/// current tab is used. If no current tab is selected, a new tab will be created.
- (void)pushURL:(NSURL *)url toTabWithTitle:(NSString *)tabTitle animated:(BOOL)animated;

/// Pops the current URL from the tab with the given title. if title is nil the
/// current tab will be used. The url is popped only if it's not the only one remaining
/// in the tab's history.
- (void)popURLFromTabWithTitle:(NSString *)tabTitle;

/// Retrieve the history of a given tab. If title is nil, the current tab will
/// be used.
- (NSArray *)urlStackForTabWithTitle:(NSString *)tabTitle;

@end
