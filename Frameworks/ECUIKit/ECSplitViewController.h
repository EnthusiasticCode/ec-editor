//
//  ECSplitViewController.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 20/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECSplitViewController : UIViewController

@property (nonatomic, copy) NSArray *viewControllers;
@property (nonatomic, strong) IBOutlet UIViewController *mainViewController;
@property (nonatomic, strong) IBOutlet UIViewController *sidebarViewController;

/// Corner radius applied to the content.
@property (nonatomic) CGFloat cornerRadius;

/// Indicates if the pan gesture should be used to show the sidebar
/// providing a direct movement of the view itself. If NO, only the swipe
/// gesture will be available to show the hidden master view.
@property (nonatomic, getter = isPanGestureEnabled) BOOL panGestureEnabled;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *swipeGestureRecognizer;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGestureRecognizer;

/// Indicates if, in the current interface orientation, the controller should
/// split the views. If NO, only the main view controller will be displayed and 
/// the sidebar view will be accessible via swipe or pan gesture.
@property (nonatomic, getter = isSplittingView) BOOL splittingView;
- (void)setSplittingView:(BOOL)value animated:(BOOL)animated;
- (BOOL)isSplittingViewForInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)setSplittingView:(BOOL)value forInterfaceOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

/// Indicates if the sidebar is displayed on the right. Default NO.
@property (nonatomic, getter = isSidebarOnRight) BOOL sidebarOnRight;

/// Indicates if the sidebar is currently visible.
@property (nonatomic, getter = isSidebarVisible) BOOL sidebarVisible;
- (void)setSidebarVisible:(BOOL)value animated:(BOOL)animated;

@end
