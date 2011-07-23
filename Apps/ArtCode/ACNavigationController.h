//
//  ACNavigationController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECJumpBar.h"
#import "ACTabController.h"
#import "ACToolTarget.h"

@class ACNavigationController;
@class ACToolPanelController;

@protocol ACNavigationControllerDelegate <NSObject>
@required

/// When implemented, return a view controller that can handle the given URL.
/// This method should chech if the previous view controller is already able to
/// open the given URL. If it is, that controller should be returned or a transition
/// will be performed.
- (UIViewController<ACToolTarget> *)navigationController:(ACNavigationController *)navigationController viewControllerForURL:(NSURL *)url previousViewController:(UIViewController<ACToolTarget> *)previousViewController;

@end


/// A navigation controller with jump bar and tabs capabilities
@interface ACNavigationController : UIViewController <ECJumpBarDelegate, ACTabControllerDelegate> 

@property (nonatomic, weak) id<ACNavigationControllerDelegate> delegate;

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet UIButton *buttonTools;
@property (nonatomic, strong) IBOutlet UIButton *buttonEdit; // TODO remember to use setEdit:animated: and editing of uiviewcontroller

#pragma mark URL Navigation Methods

/// Pushes an URL in the current tab. This method only works if delegate is 
/// set and implments navigationController:viewControllerForURL:previousViewController:.
- (void)pushURL:(NSURL *)url animated:(BOOL)animated;

- (void)popURLAnimated:(BOOL)animated;

#pragma mark Tab Navigation

@property (nonatomic, strong) IBOutlet ACTabController *tabController;

#pragma mark Tool Panel

@property (nonatomic, getter = isToolPanelEnabled) BOOL toolPanelEnabled;
@property (nonatomic, getter = isToolPanelOnRight) BOOL toolPanelOnRight;
@property (nonatomic, strong) IBOutlet ACToolPanelController *toolPanelController;

- (void)showToolPanelAnimated:(BOOL)animated;
- (void)hideToolPanelAnimated:(BOOL)animated;

#pragma mark Head Bar Methods

- (IBAction)toggleTools:(id)sender;
- (IBAction)toggleEditing:(id)sender;


- (IBAction)tests:(id)sender;

@end
