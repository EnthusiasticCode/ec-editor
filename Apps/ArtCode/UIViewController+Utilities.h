//
//  UIViewController+ContainingPopoverController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Utilities)

// The popover controller in which the view controller is presented from.
@property (nonatomic, weak) UIPopoverController *presentingPopoverController;

// Change the right bar button item with a new one containing an activity indicator that start spinning.
- (void)startRightBarButtonItemActivityIndicator;

// Restore the original bar button intem replaced by the activity indicator.
- (void)stopRightBarButtonItemActivityIndicator;

@end
