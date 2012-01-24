//
//  ACToolbarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTopBarToolbar, ACTopBarTitleControl;
@class ACTab;

@interface ACSingleTabController : UIViewController

#pragma mark Content selection

@property (nonatomic, strong) ACTab *tab;

@property (nonatomic, strong) IBOutlet UIViewController *contentViewController;
- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated;

#pragma mark Managing toolbars

@property (nonatomic, strong) IBOutlet ACTopBarToolbar *defaultToolbar;
@property (nonatomic, readonly, strong) UIView *currentToolbarView;
@property (nonatomic, strong) UIViewController *toolbarViewController;
- (void)setToolbarViewController:(UIViewController *)toolbarViewController animated:(BOOL)animated;

@property (nonatomic) CGFloat toolbarHeight;
- (void)setToolbarHeight:(CGFloat)toolbarHeight animated:(BOOL)animated;
- (void)resetToolbarHeightAnimated:(BOOL)animated;

@end


@interface UIViewController (ACSingleTabController)

- (ACSingleTabController *)singleTabController;

/// Indicates if the controller is in a loading state.
@property (nonatomic, getter = isLoading) BOOL loading;

@end


/// Protocol that can be implemented by a cotnent controller of a single tab controller 
/// to allow manipulation of the title bar.
@protocol ACSingleTabContentController <NSObject>
@optional

/// If overriden, this function indicates if the title control of the default toolbar
/// of the given single tab controller should be enabled. By default this method 
/// returns NO.
- (BOOL)singleTabController:(ACSingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(ACTopBarToolbar *)toolbar;

/// Called when the defailt toolbar title control has been tapped by the user.
- (void)singleTabController:(ACSingleTabController *)singleTabController titleControlAction:(id)sender;

/// When implemented, setup a title to the given title control. It returns YES
/// if the title control has been setup, NO otherwise.
- (BOOL)singleTabController:(ACSingleTabController *)singleTabController setupDefaultToolbarTitleControl:(ACTopBarTitleControl *)titleControl;

@end