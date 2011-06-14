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

@protocol ECFloatingSplitViewControllerDelegate <NSObject>
@optional
- (void)floatingSplitViewController:(ECFloatingSplitViewController *)floatingSplitViewController willShowSidebarController:(UIViewController *)viewController;
- (void)floatingSplitViewController:(ECFloatingSplitViewController *)floatingSplitViewController didShowSidebarController:(UIViewController *)viewController;
- (void)floatingSplitViewController:(ECFloatingSplitViewController *)floatingSplitViewController willShowMainController:(UIViewController *)viewController;
- (void)floatingSplitViewController:(ECFloatingSplitViewController *)floatingSplitViewController didShowMainController:(UIViewController *)viewController;
- (void)floatingSplitViewControllerWillHideSidebar:(ECFloatingSplitViewController *)floatingSplitViewController;
- (void)floatingSplitViewControllerDidHideSidebar:(ECFloatingSplitViewController *)floatingSplitViewController;
@end

@interface ECFloatingSplitViewController : UIViewController
@property (nonatomic, weak) IBOutlet id<ECFloatingSplitViewControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet UIViewController *sidebarController;
@property (nonatomic, strong) IBOutlet UIViewController *mainController;
@property (nonatomic) CGFloat sidebarWidth;
@property (nonatomic, getter = isSidebarHidden) BOOL sidebarHidden;
- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated;
@property (nonatomic, getter = isSidebarOnRight) BOOL sidebarOnRight;
- (void)setSidebarOnRight:(BOOL)sidebarOnRight animated:(BOOL)animated;
@property (nonatomic, getter = isSidebarFloating) BOOL sidebarFloating;
- (void)setSidebarFloating:(BOOL)sidebarFloating animated:(BOOL)animated;
- (void)setSidebarController:(UIViewController *)sidebarController withTransition:(CATransition *)transition;
- (void)setMainController:(UIViewController *)mainController withTransition:(CATransition *)transition;
@end

@interface UIViewController (ECFloatingSplitViewController)
@property (nonatomic, weak, readonly) ECFloatingSplitViewController *floatingSplitViewController;
@end