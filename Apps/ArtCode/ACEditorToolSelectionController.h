//
//  ACEditorToolSelectionController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACNavigationController;
@class ECPopoverController;

/// A view controller for a view with buttons to control the display of navigation
/// controller related tools.
@interface ACEditorToolSelectionController : UIViewController

/// The popover controller that contains this view controller.
@property (weak, nonatomic) ECPopoverController *containerPopoverController;

/// THe navigation controller to control.
@property (weak, nonatomic) ACNavigationController *targetNavigationController;

- (IBAction)tabsAction:(id)sender;

@end
