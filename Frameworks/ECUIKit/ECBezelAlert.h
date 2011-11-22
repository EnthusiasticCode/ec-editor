//
//  ECBezelAlert.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 23/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    ECBezelAlertAnimationNone = 0,
    ECBezelAlertAnimationFade = 1 << 0,
    ECBezelAlertAnimationPop  = 1 << 1
};
typedef NSInteger ECBezelAlertAnimationType;


/// Shows a bezel styled alert for a given time.
@interface ECBezelAlert : UIViewController

/// Returns the default bezel alert. By default this method returns the centerBezelAlert.
+ (ECBezelAlert *)defaultBezelAlert;

/// Return a shared instance of the bezel alert centered in the screen.
/// This allert will have a fade + pop presentation animation by default.
+ (ECBezelAlert *)centerBezelAlert;

/// Return a shared instance of the bezel alert at the bottom of the screen.
+ (ECBezelAlert *)bottomBezelAlert;

/// Specify the view controller in which the alert will be presented. If nil the allert
/// will be presented in the application's window root view controller.
@property (nonatomic, weak) UIViewController *presentingViewController;

/// Radius of rounded corners for the presented bezel view.
@property (nonatomic) CGFloat bezelCornerRadius;

/// The time for which the alert stays vivible before faigin out. Default 1 second.
@property (nonatomic) NSTimeInterval visibleTimeInterval;

/// Margins of the bezel alert from the application window. If a margin value is 
/// negative, it will be considered automatic. Default with all values automatic
/// making the bezel alert to appear at the center of the screen.
@property (nonatomic) UIEdgeInsets margins;

/// A property indicating which type of animation the bezel alert will use in presentation.
/// Default is fade in only.
@property (nonatomic) ECBezelAlertAnimationType presentationAnimationType;

/// Call this method to post a new alert message that will be displayed after the remaining posted messages.
/// If the immediate flag is YES, the alert queue will be cleared and this message will be shown immediatly.
/// The view controller may use the contentSizeForViewInPopover property to set the size of the bezel alert.
- (void)addAlertMessageWithViewController:(UIViewController *)viewController displayImmediatly:(BOOL)immediate;

/// Conviniance method to add a message with an image and a text under it.
- (void)addAlertMessageWithText:(NSString *)text image:(UIImage *)image displayImmediatly:(BOOL)immediate;

@end
