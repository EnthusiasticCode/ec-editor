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

@interface ECFloatingSplitViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIViewController *sidebarController;
@property (nonatomic, strong) IBOutlet UIViewController *mainController;
@property (nonatomic) CGFloat sidebarWidth;
- (void)setSidebarWidth:(CGFloat)sidebarWidth animated:(BOOL)animated;
@property (nonatomic) ECFloatingSplitViewControllerSidebarEdge sidebarEdge;
- (void)setSidebarEdge:(ECFloatingSplitViewControllerSidebarEdge)sidebarEdge animated:(BOOL)animated;
@property (nonatomic) BOOL sidebarLocked;
@property (nonatomic, getter = isSidebarHidden) BOOL sidebarHidden;
- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated;
@property (nonatomic, getter = isSidebarFloating) BOOL sidebarFloating;
- (void)setSidebarFloating:(BOOL)sidebarFloating animated:(BOOL)animated;
- (void)setSidebarController:(UIViewController *)sidebarController withTransition:(CATransition *)transition;
- (void)setMainController:(UIViewController *)mainController withTransition:(CATransition *)transition;
@end

@interface UIViewController (ECFloatingSplitViewController)
@property (nonatomic, weak, readonly) ECFloatingSplitViewController *floatingSplitViewController;
@end