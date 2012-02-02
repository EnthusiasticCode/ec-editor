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
#import "NSURL+Utilities.h"

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
    
    // Undo action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"undo" title:@"undo" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView.undoManager undo];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Redo action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"redo" title:@"redo" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView.undoManager redo];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Tab action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"tab" title:@"tab" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"\t"];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Curly bracket action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"openCurlyBracket" title:@"{" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"{"];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Square bracket action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"openSquareBracket" title:@"[" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"["];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Round bracket action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"openRoundBracket" title:@"(" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"("];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Angle bracket action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"openAngleBracket" title:@"<" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"<"];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Open double quote action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"openDoubleQuote" title:@"\"" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"\""];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Open single quote action
    action = [[CodeFileAccessoryAction alloc] initWithName:@"openSingleQuote" title:@"'" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@"'"];
    }];
    [actionDictionary setObject:action forKey:action.name];
    
    // Add a esmicolon and return at the current location
    action = [[CodeFileAccessoryAction alloc] initWithName:@"semicolonReturn" title:@";" imageNamed:nil actionBlock:^(CodeFileController *controller, NSUInteger accessoryButtonIndex) {
        [controller.codeView insertText:@";\n"];
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
#warning TODO NIK load plist, possibly in tm bundle
//    if (!systemDefaultAccessoryActions)
//        systemDefaultAccessoryActions = [NSArray arrayWithObjects:[systemAccessoryActions objectForKey:@"semicolonReturn"], [systemAccessoryActions objectForKey:@"addAsd"], nil];
    return [systemAccessoryActions allValues];
}

+ (NSArray *)defaultActionsForLanguageWithIdentifier:(NSString *)languageIdentifier
{
    // TODO load from plist
    return [[systemAccessoryActions allValues] subarrayWithRange:NSMakeRange(0, 11)];
}

@end
