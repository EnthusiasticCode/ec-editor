//
//  TMKeyboardAction.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 04/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TMKeyboardActionTarget;

@interface TMKeyboardAction : NSObject

#pragma mark Accessing the action properties

/// Name used as identifier for this action.
@property (nonatomic, readonly, strong) NSString *name;

/// Scope in which the action is valid.
@property (nonatomic, readonly, strong) NSString *scope;

/// Title to use to represent this action. This property can be nil.
@property (nonatomic, readonly, strong) NSString *title;

/// A short description of the action. This property can be nil.
@property (nonatomic, readonly, strong) NSString *description;

/// Image name to represent this action. If not set, it will be generated from the action's name.
@property (nonatomic, readonly, strong) NSString *imagePath;

/// Returns an image that represent the keyboard action and that can be used
/// on a button. This method can return nil if no image for the action has been found.
- (UIImage *)image;

#pragma mark Create and execute the action

- (id)initWithName:(NSString *)name scope:(NSString *)scope title:(NSString *)title description:(NSString *)description imagePath:(NSString *)imagePath commands:(NSArray *)commands;
- (void)executeActionOnTarget:(id<TMKeyboardActionTarget>)target;

#pragma mark Actions grouping

+ (NSDictionary *)allKeyboardActions;
+ (TMKeyboardAction *)keyboardActionForName:(NSString *)name;

@end


@protocol TMKeyboardActionTarget <NSObject>
@required

/// Returns a boolean value indicating if the given selector can be performed
/// by the keyboard action on the receiver.
- (BOOL)keyboardAction:(TMKeyboardAction *)keyboardAction canPerformSelector:(SEL)selector;

@end
