//
//  ACNavigationController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECJumpBar.h"
#import "ECPopoverController.h"
#import "ECTabBar.h"
#import "ECSwipeGestureRecognizer.h"


@interface ACNavigationController : UIViewController <ECJumpBarDelegate, ECTabBarDelegate> 

@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet UIButton *buttonTools;
@property (nonatomic, strong) IBOutlet UIButton *buttonEdit; // TODO remember to use setEdit:animated: and editing of uiviewcontroller

#pragma mark Navigation Methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;

#pragma mark Tab Navigation

@property (nonatomic, getter = isTabBarEnabled) BOOL tabBarEnabled;
@property (nonatomic, strong) IBOutlet ECTabBar *tabBar;

#pragma mark Tool Panel

@property (nonatomic, getter = isToolPanelEnabled) BOOL toolPanelEnabled;
@property (nonatomic, getter = isToolPanelOnRight) BOOL toolPanelOnRight;
@property (nonatomic, strong) IBOutlet UIViewController *toolPanelController;

- (void)showToolPanelAnimated:(BOOL)animated;
- (void)hideToolPanelAnimated:(BOOL)animated;

#pragma mark Head Bar Methods

- (IBAction)toggleTools:(id)sender;
- (IBAction)toggleEditing:(id)sender;

#pragma mark Tab Bar Methods

- (IBAction)toggleTabBar:(id)sender;
- (IBAction)closeTabButtonAction:(id)sender;


- (IBAction)tests:(id)sender;

@end
