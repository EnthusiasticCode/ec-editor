//
//  ACNavigationController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECJumpBar.h"
#import "ACTabNavigationController.h"
#import "ACNavigationTarget.h"

@class ACNavigationController;
@class ACToolPanelController;


/// A navigation controller with jump bar and tabs capabilities
@interface ACNavigationController : UIViewController <ECJumpBarDelegate, ACTabNavigationControllerDelegate> 

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet UIView *topBarView;
@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet UIButton *buttonTools;
@property (nonatomic, strong) IBOutlet UIButton *buttonEdit; // TODO remember to use setEdit:animated: and editing of uiviewcontroller

#pragma mark Tab Navigation

@property (nonatomic, strong) IBOutlet ACTabNavigationController *tabNavigationController;

/// Conviniance method to push an URL to the current tab's history
- (void)pushURL:(NSURL *)url;

#pragma mark Tool Panel

@property (nonatomic, getter = isToolPanelEnabled) BOOL toolPanelEnabled;
@property (nonatomic, getter = isToolPanelOnRight) BOOL toolPanelOnRight;
@property (nonatomic, strong) IBOutlet ACToolPanelController *toolPanelController;

- (void)showToolPanelAnimated:(BOOL)animated;
- (void)hideToolPanelAnimated:(BOOL)animated;

#pragma mark Head Bar Methods

- (IBAction)toolButtonAction:(id)sender;
- (IBAction)editButtonAction:(id)sender;

@end

@interface UIViewController (ACNavigationController)
- (ACNavigationController *)ACNavigationController;
@end
