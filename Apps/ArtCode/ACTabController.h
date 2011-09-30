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
@class ACTab;

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
- (id)initWithTab:(ACTab *)tab;

#pragma mark Accessing Tab's Environment

/// Delegate of the tab.
@property (nonatomic, weak) id<ACTabControllerDelegate> delegate;

/// Tab object the tab controller is displaying
@property (nonatomic, strong) ACTab *tab;

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
/// controller if not already existing.
/// The view controller may implement a method setScrollToRequireGestureRecognizerToFail:
/// receiving a UIGestureRecognizer that should be required to fail for every controlled
///scrolling view.
@property (nonatomic, readonly, strong) UIViewController *tabViewController;

/// Returns true if the tabViewController property is not nil without triggering 
/// a view controller creation.
@property (nonatomic, readonly) BOOL isTabViewControllerLoaded;

@end
