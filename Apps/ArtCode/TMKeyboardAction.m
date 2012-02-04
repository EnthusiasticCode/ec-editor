//
//  TMKeyboardAction.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 04/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMKeyboardAction.h"
#import "TMBundle.h"
#import <objc/message.h>

static NSMutableDictionary *systemKeyboardActions;
static NSString * const keyboardActionsDirectory = @"KeyboardActions";

@implementation TMKeyboardAction {
    UIImage *_image;
    NSArray *_commands;
}

#pragma mark - Properties

@synthesize name, scope, title, description, imagePath;

- (NSString *)imagePath
{
    if (imagePath == nil)
        imagePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"keyboardAction_%@", self.name] ofType:nil];
    return imagePath;
}

- (UIImage *)image
{
    if (!_image)
    {
        _image = [UIImage imageWithContentsOfFile:self.imagePath];
    }
    return _image;
}

#pragma mark - Public methods

- (id)initWithName:(NSString *)aName scope:(NSString *)aScope title:(NSString *)aTitle description:(NSString *)aDescription imagePath:(NSString *)anImagePath commands:(NSArray *)commands
{
    self = [super init];
    if (!self)
        return nil;
    name = aName;
    scope = aScope;
    title = aTitle;
    description = aDescription;
    if (anImagePath)
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:anImagePath])
            imagePath = [[NSBundle mainBundle] pathForResource:anImagePath ofType:nil];
        else
            imagePath = anImagePath;
    }
    _commands = commands;
    return self;
}

- (void)executeActionOnTarget:(id<TMKeyboardActionTarget>)target
{
    ECASSERT(target);
    
    for (NSDictionary *command in _commands)
    {
        if (![target keyboardAction:self canPerformSelector:NSSelectorFromString([command objectForKey:@"command"])])
            continue;
        objc_msgSend(target, NSSelectorFromString([command objectForKey:@"command"]), [command objectForKey:@"argument"]);
    }
}

#pragma mark Class methods

+ (void)_loadKeyboardActionsFromFileURL:(NSURL *)fileURL
{
    if (!systemKeyboardActions)
        systemKeyboardActions = [NSMutableDictionary new];
    for (NSDictionary *action in [[NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL] objectForKey:@"keyboardActions"])
    {
        [systemKeyboardActions setObject:[[TMKeyboardAction alloc] initWithName:[action objectForKey:@"name"] scope:[action objectForKey:@"scope"] title:[action objectForKey:@"title"] description:[action objectForKey:@"description"] imagePath:[action objectForKey:@"imagePath"] commands:[action objectForKey:@"commands"]] forKey:[action objectForKey:@"name"]];
    }
}

+ (NSDictionary *)allKeyboardActions
{
    if (!systemKeyboardActions)
    {
        for (TMBundle *tmBundle in [TMBundle allBundles])
        {
            for (NSURL *keyboardActionURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[[tmBundle URL] URLByAppendingPathComponent:keyboardActionsDirectory isDirectory:YES] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
            {
                [self _loadKeyboardActionsFromFileURL:keyboardActionURL];
            }
        }
    }
    return systemKeyboardActions;
}

+ (TMKeyboardAction *)keyboardActionForName:(NSString *)name
{
    return [[self allKeyboardActions] objectForKey:name];
}

@end
