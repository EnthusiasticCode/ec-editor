//
//  ACCodeFileAccessoryAction.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECCodeView;

typedef void(^ACCodeFileAccessoryActionBlock)(ECCodeView *codeView);

@interface ACCodeFileAccessoryAction : NSObject

/// Name used as identifier for this action.
@property (nonatomic, readonly, strong) NSString *name;

/// Title to use to represent this action. This property can be nil.
@property (nonatomic, readonly, strong) NSString *title;

/// Image name to represent this action. If not set, it will be generated from the action's name.
@property (nonatomic, readonly, strong) NSString *imageName;

/// The block of code to execute when this action is selected.
@property (nonatomic, readonly, copy) ACCodeFileAccessoryActionBlock actionBlock;

/// Initialize a new accessory action.
- (id)initWithName:(NSString *)name title:(NSString *)title imageNamed:(NSString *)imageName actionBlock:(ACCodeFileAccessoryActionBlock)actionBlock;
- (id)initWithName:(NSString *)name actionBlock:(ACCodeFileAccessoryActionBlock)actionBlock;

#pragma mark Actions Grouping

+ (ACCodeFileAccessoryAction *)accessoryActionWithName:(NSString *)actionName;
+ (NSArray *)accessoryActionsForLanguageWithIdentifier:(NSString *)languageIdentifier;

@end

