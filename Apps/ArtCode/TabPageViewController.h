//
//  TabPageViewController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TabPageViewController, TabBar;


@protocol TabPageViewControllerDataSource <NSObject>
@required

// Returns the view controller for the given tab index.
// This method should take care of returning the same controller for a given index if it didn't changed in the model.
- (UIViewController *)tabPageViewController:(TabPageViewController *)tabPageController viewControllerForTabAtIndex:(NSUInteger)tabIndex;

@end

// Controller to manage a tab bar that shows a controller provided by the datasource when its selection change.
// Use tabBar methods to add, move or remove tabs.
@interface TabPageViewController : UIViewController

@property (nonatomic, weak) id<TabPageViewControllerDataSource> dataSource;

#pragma mark Display options

@property (nonatomic, getter = isTabBarVisible) BOOL tabBarVisible;
- (void)setTabBarVisible:(BOOL)tabBarVisible animated:(BOOL)animated;

#pragma mark Views and recognizers

// The tab bar used to show the tabs. The delegate of the tabbar can be used to monitor changes of the visual tabs.
@property (nonatomic, strong, readonly) TabBar *tabBar;

// The gesture recognizers used to show and hide the tab bar
@property (nonatomic, strong, readonly) NSArray *gestureRecognizers;

@end


@interface UIViewController (TabPageViewController)

// Gets the parent tab page view controller if any.
- (TabPageViewController *)tabPageViewController;

@end