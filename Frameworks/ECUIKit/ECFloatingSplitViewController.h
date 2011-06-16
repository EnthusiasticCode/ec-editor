//
//  ECFloatingSplitViewController.h
//  edit
//
//  Created by Uri Baghin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CATransition;
@class ECFloatingSplitViewController;

typedef enum
{
    ECFloatingSplitViewControllerSidebarEdgeTop,
    ECFloatingSplitViewControllerSidebarEdgeBottom,
    ECFloatingSplitViewControllerSidebarEdgeLeft,
    ECFloatingSplitViewControllerSidebarEdgeRight,
} ECFloatingSplitViewControllerSidebarEdge;

/// A view controller that presents a main view controller and a sidebar similar to \c UISplitViewController but with several customization options.
@interface ECFloatingSplitViewController : UIViewController
/// The view controller that provides the sidebar contents.
@property (nonatomic, strong) IBOutlet UIViewController *sidebarController;
- (void)setSidebarController:(UIViewController *)sidebarController withTransition:(CATransition *)transition;
/// The view controller that provides the contents for the main view area.
@property (nonatomic, strong) IBOutlet UIViewController *mainController;
- (void)setMainController:(UIViewController *)mainController withTransition:(CATransition *)transition;
/// The width of the sidebar. If the sidebar is docked at the top or bottom of the main area, the width will be used as height.
@property (nonatomic) CGFloat sidebarWidth;
- (void)setSidebarWidth:(CGFloat)sidebarWidth animated:(BOOL)animated;
/// The edge to which the sidebar is docked.
@property (nonatomic) ECFloatingSplitViewControllerSidebarEdge sidebarEdge;
- (void)setSidebarEdge:(ECFloatingSplitViewControllerSidebarEdge)sidebarEdge animated:(BOOL)animated;
/// If the sidebar is locked, it cannot be hidden or shown with a swipe. It can still be hidden and shown programmatically.
@property (nonatomic) BOOL sidebarLocked;
/// Hides or shows the sidebar.
@property (nonatomic, getter = isSidebarHidden) BOOL sidebarHidden;
- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated;
/// Specifies whether the sidebar should be presented floating on top of the main view area, or on the side.
@property (nonatomic, getter = isSidebarFloating) BOOL sidebarFloating;
- (void)setSidebarFloating:(BOOL)sidebarFloating animated:(BOOL)animated;
@end

@interface UIViewController (ECFloatingSplitViewController)
/// Returns the closest \c ECFloatingSplitViewController ancestor of the view controller.
@property (nonatomic, weak, readonly) ECFloatingSplitViewController *floatingSplitViewController;
@end
