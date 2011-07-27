//
//  ACTabController.h
//  tab
//
//  Created by Nicola Peduzzi on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACTabController;
@class ACTabNavigationController;

@protocol ACTabControllerDataSource <NSObject>
@required

/// Returns a view controller initialized with the given URL.
- (UIViewController *)tabController:(ACTabController *)tabController viewControllerForURL:(NSURL *)url;

@optional

/// Ask the datasource if the given view controller can not handle the provided URL
/// and should be dismissed.
/// If it can, this method should make the view controller open the given URL.
/// The provided view controller is equal to the one returned by the tabViewController
/// property; but if nil, it will not be created during this call.
/// If not implemented, the default behaviour act as if this method always return YES,
/// making the tabViewController property being set to nil and thus, making a new
/// call to that property invoke the tabController:viewControllerForURL: data source method.
- (BOOL)tabController:(ACTabController *)tabController shouldChangeCurrentViewController:(UIViewController *)viewController forURL:(NSURL *)url;

@end


@protocol ACTabControllerDelegate <NSObject>
@optional

/// Informs the delegate that the current URL has changed to the one given and 
/// provides the view controller that was handling the previous URL. This view
/// controller may be equal to the one returned by the tabViewController property.
/// An implementation should call the tabViewController property
/// to retrieve or create the view controller for the new URL.
- (void)tabController:(ACTabController *)tabController didChangeURL:(NSURL *)url previousViewController:(UIViewController *)previousVewController;

@end


/// Control a single tab. This class expose the tab history and keep track of
/// the current view controller for the tab.
@interface ACTabController : NSObject <NSCopying> {
@private
    __weak ACTabNavigationController *parentTabNavigationController;
    __weak UIControl *tabButton;
}

#pragma mark Create Tab Controllers

/// Create a new tab controller with a single URL in its history.
- (id)initWithDataSource:(id<ACTabControllerDataSource>)datasource URL:(NSURL *)initialURL;

#pragma mark Accessing Tab's Environment

/// Data source of the tab. If nil, some methods will not work properly.
@property (nonatomic, weak) id<ACTabControllerDataSource> dataSource;

/// Delegate of the tab.
@property (nonatomic, weak) id<ACTabControllerDelegate> delegate;

/// Returns the tab navigation controller that manage this tab.
@property (nonatomic, readonly, weak) ACTabNavigationController *parentTabNavigationController;

/// Convenience property that indicate if the receiver is the current tab controller in its parent.
@property (nonatomic, readonly) BOOL isCurrentTabController;

/// The position of the tab in the parent tab navigation controller.
@property (nonatomic, readonly) NSUInteger position;

#pragma mark Tab Controls

/// A reference to the control used to switch to the tab.
@property (nonatomic, readonly, weak) UIControl *tabButton;

/// A reference to the view controller that manages the current tab URL.
/// Accessing this property will trigger the allocation of a proper view 
/// controller if not already existing. This method requires the delegate's 
/// tabController:viewControllerForURL: method to be implemented.
/// The property is weak, if the created view controller will not be strongly
/// retained, usually by a parent view controller, it will be immediatly deallocated.
@property (nonatomic, readonly, weak) UIViewController *tabViewController;

/// Returns true if the tabViewController property is not nil without triggering 
/// a view controller creation.
@property (nonatomic, readonly) BOOL isTabViewControllerLoaded;

#pragma mark Managing Tab's History

/// Returns an array of all URLs in the tab's history.
@property (nonatomic, readonly, copy) NSArray *historyURLs;

/// The current URL the tab history is pointing at. This property is read only.
/// To change the current URL use one of the move methods or pushURL.
@property (nonatomic, readonly) NSURL *currentURL;

/// A value indicating if calling moveBackInHistoryAnimated: will have any effect.
@property (nonatomic, readonly) BOOL canMoveBack;

/// A value indicating if calling moveForwardInHistoryAnimated: will have any effect.
@property (nonatomic, readonly) BOOL canMoveForward;

/// Pushes an URL to the tab's history.
- (void)pushURL:(NSURL *)url;

/// Move in the tab's history. The index is relative to the historyURLs array.
- (void)moveToHistoryURLAtIndex:(NSUInteger)URLIndex;

/// Convinience method that moves the tab's history back by one step.
- (void)moveBackInHistory;

/// Convinience method that moves the tab's history forward by one step.
- (void)moveForwardInHistory;

@end
