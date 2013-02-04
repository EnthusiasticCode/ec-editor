//
//  TMKeyboardAction.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 04/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TMKeyboardActionTarget;


// Represent keyboard actions and give access to keyboard actions configurations
// specified in the textmate bundles. 
// A plist may be formed by:
// scope: the scope selector that indicates which scopes should use this keyboard.
// keyboardActions: and array of keyboard action dictionaries
//     <keyboard action>: uuid, title, description and imagePath are strings (relative to the plist file when needed),
//                        commands is an array of dictionaries containing command and argument to execute a selector.
// keyboardActionsConfiguration: an ordered array of keyboard action's uuid or the string 'inherit' that specify a keyboard configuration.
@interface TMKeyboardAction : NSObject

#pragma mark Accessing the action properties

// UUID used as identifier for this action.
@property (nonatomic, readonly, strong) NSString *uuid;

// Title to use to represent this action. This property can be nil.
@property (nonatomic, readonly, strong) NSString *title;

// A short description of the action. This property can be nil.
@property (nonatomic, readonly, strong) NSString *description;

// Image name to represent this action. If not set, it will be generated from the action's name.
@property (nonatomic, readonly, strong) NSString *imagePath;

// Returns an image that represent the keyboard action and that can be used
// on a button. This method can return nil if no image for the action has been found.
- (UIImage *)image;

#pragma mark Create and execute the action

- (id)initWithUUID:(NSString *)uuid title:(NSString *)title description:(NSString *)description imagePath:(NSString *)imagePath commands:(NSArray *)commands;
- (void)executeActionOnTarget:(id<TMKeyboardActionTarget>)target;

#pragma mark Actions grouping

// A dictionary of all keyboard actions mapped by UUID.
+ (NSDictionary *)allKeyboardActions;

#pragma mark Configurations

+ (NSArray *)defaultKeyboardActionsConfiguration;
+ (NSDictionary *)allKeyboardActionsConfigurations;
+ (NSArray *)keyboardActionsConfigurationForQualifiedIdentifier:(NSString *)qualifiedIdentifier;

@end


@protocol TMKeyboardActionTarget <NSObject>
@required

// Returns a boolean value indicating if the given selector can be performed
// by the keyboard action on the receiver.
- (BOOL)keyboardAction:(TMKeyboardAction *)keyboardAction canPerformSelector:(SEL)selector;

@end
