//
//  ECTripleSplitViewController.h
//  edit
//
//  Created by Uri Baghin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CATransition;
@class ECTripleSplitViewController;

@protocol ECTripleSplitViewControllerDelegate <NSObject>
@optional
- (void)tripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController willShowMenuController:(UIViewController *)viewController;
- (void)tripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController didShowMenuController:(UIViewController *)viewController;
- (void)tripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController willShowSidebarController:(UIViewController *)viewController;
- (void)tripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController didShowSidebarController:(UIViewController *)viewController;
- (void)tripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController willShowMainController:(UIViewController *)viewController;
- (void)tripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController didShowMainController:(UIViewController *)viewController;
- (void)tripleSplitViewControllerWillHideSidebar:(ECTripleSplitViewController *)tripleSplitViewController;
- (void)tripleSplitViewControllerDidHideSidebar:(ECTripleSplitViewController *)tripleSplitViewController;
@end

@interface ECTripleSplitViewController : UIViewController
@property (nonatomic, weak) IBOutlet id<ECTripleSplitViewControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet UIViewController *menuController;
@property (nonatomic, strong) IBOutlet UIViewController *sidebarController;
@property (nonatomic, strong) IBOutlet UIViewController *mainController;
@property (nonatomic) CGFloat menuWidth;
@property (nonatomic) CGFloat sidebarWidth;
@property (nonatomic) BOOL sidebarHidden;
- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated;
- (void)setMenuController:(UIViewController *)menuController withTransition:(CATransition *)transition;
- (void)setSidebarController:(UIViewController *)sidebarController withTransition:(CATransition *)transition;
- (void)setMainController:(UIViewController *)mainController withTransition:(CATransition *)transition;
@end

@interface UIViewController (ECTripleSplitViewController)
@property (nonatomic, weak, readonly) ECTripleSplitViewController *tripleSplitViewController;
@end