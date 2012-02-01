//
//  CodeFileAccessoryAction.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFileAccessoryAction.h"
#import "CodeFileController.h"
#import "CodeView.h"

@implementation CodeFileAccessoryAction

@synthesize name, title, imageName, actionBlock;

- (NSString *)imageName
{
    if (!imageName)
        return [NSString stringWithFormat:@"accessoryAction_%@", self.name];
    return imageName;
}

- (id)initWithName:(NSString *)_name title:(NSString *)_title imageNamed:(NSString *)_imageName actionBlock:(CodeFileAccessoryActionBlock)_actionBlock
{
    ECASSERT(_name != nil);
    ECASSERT(_actionBlock != nil);
    
    self = [super init];
    if (!self)
        return nil;
    
    name = _name;
    title = _title;
    imageName = _imageName;
    actionBlock = [_actionBlock copy];
    return self;
}

- (id)initWithName:(NSString *)_name actionBlock:(CodeFileAccessoryActionBlock)_actionBlock
{
    return [self initWithName:_name title:nil imageNamed:nil actionBlock:_actionBlock];
}

#pragma mark - Class Methods

/// Dictionary of action name -> action.
static NSDictionary *systemAccessoryActions = nil;
static NSArray *systemDefaultAccessoryActions = nil;

+ (void)initialize
{
    if (self != [CodeFileAccessoryAction class])
        return;
    NSMutableDictionary *actionDictionary = [NSMutableDictionary new];
    CodeFileAccessoryAction *action = nil;
    
    // Code completion action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"codeCompletion" title:@"comp" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller showCompletionPopoverForCurrentSelectionAtKeyboardAccessoryItemIndex:accessoryButtonIndex];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Add a comma and return at the current location
    action = [[CodeFileAccessoryAction alloc] initWithName:@"commaReturn" title:@";" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@";\n"];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // TODO test button
    action = [[CodeFileAccessoryAction alloc] initWithName:@"addAsd" title:@"asd" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"asd"];
    }];
    [actionDictionary setObject:action forKey:action.name];
        
    systemAccessoryActions = actionDictionary;
}

+ (CodeFileAccessoryAction *)accessoryActionWithName:(NSString *)actionName
{
    ECASSERT(actionName != nil);
    return [systemAccessoryActions objectForKey:actionName];
}

+ (NSArray *)accessoryActionsForLanguageWithIdentifier:(NSString *)languageIdentifier
{
#warning TODO NIK load plist
    if (!systemDefaultAccessoryActions)
        systemDefaultAccessoryActions = [NSArray arrayWithObjects:[systemAccessoryActions objectForKey:@"commaReturn"], [systemAccessoryActions objectForKey:@"addAsd"], nil];
    return systemDefaultAccessoryActions;
}

@end
