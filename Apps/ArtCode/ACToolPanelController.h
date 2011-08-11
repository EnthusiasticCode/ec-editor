//
//  ACToolPanelController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACToolController.h"

@interface ACToolPanelController : UIViewController

/// The view containing the tab buttons.
@property (nonatomic, strong) IBOutlet UIView *tabsView;

#pragma mark Managing Tools by Identifiers

/// An array of all the tool controller identifiers usable by the receiver.
@property (nonatomic, readonly, strong) NSArray *toolControllerIdentifiers;

/// Gets or set an array of identifiers that will indicate which tools to dispaly.
/// Identifiers in this array must appear in the toolControllerIdentifiers array.
@property (nonatomic, strong) NSArray *enabledToolControllerIdentifiers;

#pragma mark Managing Tools by Controller

/// An array containing all the tool controllers currently enabled via enabledToolControllerIdentifiers.
@property (nonatomic, readonly, strong) NSArray *enabledToolControllers;

@property (nonatomic, strong) ACToolController *selectedViewController;
- (void)setSelectedViewController:(ACToolController *)controller animated:(BOOL)animated;

@end
