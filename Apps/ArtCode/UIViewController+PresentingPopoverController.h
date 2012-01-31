//
//  UIViewController+ContainingPopoverController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (PresentingPopoverController)

/// The popover controller in which the view controller is presented from.
@property (nonatomic, weak) UIPopoverController *presentingPopoverController;

@end
