//
//  TMKeyboardAction.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 04/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMKeyboardAction.h"
#import "TMBundle.h"
#import "TMScope.h"
#import <objc/message.h>

static NSMutableDictionary *systemKeyboardActions;
static NSMutableDictionary *systemKeyboardActionsConfigurations;
static NSString * const keyboardActionsDirectory = @"KeyboardActions";

@implementation TMKeyboardAction {
    UIImage *_image;
    NSArray *_commands;
}

#pragma mark - Properties

@synthesize uuid, title, description, imagePath;

- (NSString *)imagePath
{
    if (imagePath == nil)
        imagePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"keyboardAction_%@", self.uuid] ofType:nil];
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

- (id)initWithUUID:(NSString *)anUUID title:(NSString *)aTitle description:(NSString *)aDescription imagePath:(NSString *)anImagePath commands:(NSArray *)commands
{
    self = [super init];
    if (!self)
        return nil;
    uuid = anUUID;
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
    ASSERT(target);
    
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
    NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    ASSERT(plist != nil);
    // Load actions
    for (NSDictionary *action in [plist objectForKey:@"keyboardActions"])
    {
        [systemKeyboardActions setObject:[[TMKeyboardAction alloc] initWithUUID:[action objectForKey:@"uuid"] title:[action objectForKey:@"title"] description:[action objectForKey:@"description"] imagePath:[action objectForKey:@"imagePath"] commands:[action objectForKey:@"commands"]] forKey:[action objectForKey:@"uuid"]];
    }
    // Load configuration
    NSMutableArray *configuration = [NSMutableArray new];
    for (NSString *actionUUID in [plist objectForKey:@"keyboardActionsConfiguration"])
    {
        if ([actionUUID length] == 0 || [actionUUID isEqualToString:@"inherit"])
            [configuration addObject:[NSNull null]];
        else
            [configuration addObject:[systemKeyboardActions objectForKey:actionUUID]];
    }
    // Add configuration to system list
    if (!systemKeyboardActionsConfigurations)
        systemKeyboardActionsConfigurations = [NSMutableDictionary new];
    for (NSString *scope in [[plist objectForKey:@"scope"] componentsSeparatedByString:@","])
    {
        [systemKeyboardActionsConfigurations setObject:[configuration copy] forKey:scope];
    }
}

+ (NSDictionary *)allKeyboardActionsConfigurations
{
    if (!systemKeyboardActionsConfigurations)
    {
        for (NSURL *bundleURL in [TMBundle bundleURLs])
        {
            for (NSURL *keyboardActionURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:keyboardActionsDirectory isDirectory:YES] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
            {
                [self _loadKeyboardActionsFromFileURL:keyboardActionURL];
            }
        }
    }
    return systemKeyboardActionsConfigurations;
}

+ (NSArray *)keyboardActionsConfigurationForScope:(TMScope *)scope
{
    // TODO handle "inherit" actions?
    __block NSArray *configuration = nil;
    [[self allKeyboardActionsConfigurations] enumerateKeysAndObjectsUsingBlock:^(NSString *scopeSelector, NSArray *conf, BOOL *stop) {
        if ([scope scoreForScopeSelector:scopeSelector] > 0)
        {
            configuration = conf;
            *stop = YES;
        }
    }];
    return configuration;
}

@end
