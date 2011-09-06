//
//  ACToolTarget.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACToolController;

// TODO rename/rework this protocol
// TODO integrate in navigation controller didChangeCurrentTabController..
@protocol ACNavigationTarget <NSObject>
@required

/// When implemented, create a new view controller that responds to the protocol methods.
+ (id)newNavigationTargetController;

/// Makes the target open the given URL.
- (void)openURL:(NSURL *)url;

/// Indicates if the tab bar can be displayed when the target is in foreground.
- (BOOL)enableTabBar;

/// Indicates if the tool controller with the given identifier should be enabled 
/// when the target is in foreground.
- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier;

@optional

/// Returns a UIButton that will be placed on the left of the jump bar.
@property (nonatomic, readonly, strong) UIButton *toolButton;

/// Provide the delegate to be connected to the given text field. 
/// The controller can change properties of the text field; but connecting actions
/// to it will result in unwanted behaviours when the text field will be associated
/// to a different controller.
- (id<UITextFieldDelegate>)delegateForFilterField:(UITextField *)textField;

/// Used to indicate that the controller should make every scrolling view to require
/// the given recognizer to fail.
- (void)setScrollToRequireGestureRecognizerToFail:(UIGestureRecognizer *)recognizer;

@end
