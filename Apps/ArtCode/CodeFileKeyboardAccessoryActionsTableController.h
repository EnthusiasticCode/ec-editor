//
//  CodeFileKeyboardAccessoryActionsTableController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CodeFileAccessoryAction;

@interface CodeFileKeyboardAccessoryActionsTableController : UITableViewController

/// Specify the language identifier to be used to retrieve the set of actions to show.
@property (nonatomic, strong) NSString *languageIdentifier;

/// Block to be executed when the user select an action item.
@property (nonatomic, copy) void (^didSelectActionItemBlock)(CodeFileKeyboardAccessoryActionsTableController *sender, CodeFileAccessoryAction *action);

/// The background image to use for the button previews.
@property (nonatomic, strong) UIImage *buttonBackgroundImage;

@end
