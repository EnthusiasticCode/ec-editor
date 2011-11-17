//
//  ACCodeFileAccessoryAction.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileAccessoryAction.h"
#import <ECUIKit/ECCodeView.h>

@implementation ACCodeFileAccessoryAction

@synthesize name, title, imageName, actionBlock;

- (NSString *)imageName
{
    if (!imageName)
        return [NSString stringWithFormat:@"accessoryAction_%@", self.name];
    return imageName;
}

- (id)initWithName:(NSString *)_name title:(NSString *)_title imageNamed:(NSString *)_imageName actionBlock:(ACCodeFileAccessoryActionBlock)_actionBlock
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

- (id)initWithName:(NSString *)_name actionBlock:(ACCodeFileAccessoryActionBlock)_actionBlock
{
    return [self initWithName:_name title:nil imageNamed:nil actionBlock:_actionBlock];
}

#pragma mark - Class Methods

/// Dictionary of action name -> action.
static NSDictionary *systemAccessoryActions = nil;
static NSArray *systemDefaultAccessoryActions = nil;

+ (void)initialize
{
    NSMutableDictionary *actionDictionary = [NSMutableDictionary new];
    ACCodeFileAccessoryAction *action = nil;
    
    // Add a comma and return at the current location
    action = [[ACCodeFileAccessoryAction alloc] initWithName:@"commaReturn" title:@";" imageNamed:nil actionBlock:^(ECCodeView *codeView) {
        [codeView insertText:@";\n"];
    }];
    [actionDictionary setObject:action forKey:action.name];
        
    systemAccessoryActions = actionDictionary;
}

+ (ACCodeFileAccessoryAction *)accessoryActionWithName:(NSString *)actionName
{
    ECASSERT(actionName != nil);
    return [systemAccessoryActions objectForKey:actionName];
}

+ (NSArray *)accessoryActionsForLanguageWithIdentifier:(NSString *)languageIdentifier
{
#warning TODO NIK load plist
    if (!systemDefaultAccessoryActions)
        systemDefaultAccessoryActions = [NSArray arrayWithObjects:[systemAccessoryActions objectForKey:@"commaReturn"], nil];
    return systemDefaultAccessoryActions;
}

@end
