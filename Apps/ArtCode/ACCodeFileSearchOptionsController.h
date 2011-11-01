//
//  ACCodeFileSearchOptionsController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCodeFileSearchBarController;

@interface ACCodeFileSearchOptionsController : UITableViewController

/// The parent search bar controller that will display this options.
@property (weak, nonatomic) ACCodeFileSearchBarController *parentSearchBarController;

/// The popover controller displaying this controller if any.
@property (weak, nonatomic) UIPopoverController *parentPopoverController;

@end
