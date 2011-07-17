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
#import "ACNavigable.h"

@class ACNavigationController;
@class ACToolPanelController;

@protocol ACNavigationControllerDelegate <NSObject>
@required

/// When implemented, return a view controller that can handle the given URL.
/// This method should chech if the current view controller is already able to
/// open the given URL. If it is, that controller should be returned or a transition
/// will be performed.
- (UIViewController<ACNavigable> *)navigationController:(ACNavigationController *)navigationController viewControllerForURL:(NSURL *)url;

@end

/// A navigation controller with jump bar and tabs capabilities
@interface ACNavigationController : UIViewController <ECJumpBarDelegate, ECTabBarDelegate> 

@property (nonatomic, weak) id<ACNavigationControllerDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet UIButton *buttonTools;
@property (nonatomic, strong) IBOutlet UIButton *buttonEdit; // TODO remember to use setEdit:animated: and editing of uiviewcontroller

#pragma mark Navigation Methods

@property (nonatomic, readonly) UIViewController<ACNavigable> *currentViewController;
- (void)pushViewController:(UIViewController<ACNavigable> *)viewController animated:(BOOL)animated;
- (UIViewController<ACNavigable> *)popViewControllerAnimated:(BOOL)animated;

#pragma mark URL Navigation Methods

// TODO
/// Pushes an URL in the current tab. This method only works if delegate is 
/// set and implments navigationController:viewControllerForURL:.
- (void)pushURL:(NSURL *)url animated:(BOOL)animated;

#pragma mark Tab Navigation

@property (nonatomic, getter = isTabBarEnabled) BOOL tabBarEnabled;
@property (nonatomic, strong) IBOutlet ECTabBar *tabBar;

#pragma mark Tool Panel

@property (nonatomic, getter = isToolPanelEnabled) BOOL toolPanelEnabled;
@property (nonatomic, getter = isToolPanelOnRight) BOOL toolPanelOnRight;
@property (nonatomic, strong) IBOutlet ACToolPanelController *toolPanelController;

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
