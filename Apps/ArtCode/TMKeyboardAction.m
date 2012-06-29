//
//  TMKeyboardAction.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 04/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMKeyboardAction.h"
#import "TMBundle.h"
#import "NSString+TextMateScopeSelectorMatching.h"
#import <objc/message.h>

static NSMutableDictionary *systemKeyboardActions;
static NSMutableDictionary *systemKeyboardActionsConfigurations;
static NSArray *systemDefaultKeyboardActionsConfiguration;
static NSString * const keyboardConfigurationsPath = @"KeyboardConfigurations";
static NSString * const keyboardActionsPath = @"KeyboardConfigurations/KeyboardActions";

@interface TMKeyboardAction ()

- (id)initWithDictionary:(NSDictionary *)dict;

@end


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

#pragma mark Private methods

- (id)initWithDictionary:(NSDictionary *)dict {
  ASSERT(dict);
  self = [self initWithUUID:[dict objectForKey:@"uuid"] 
                      title:[dict objectForKey:@"title"] 
                description:[dict objectForKey:@"description"] 
                  imagePath:[dict objectForKey:@"imagePath"] 
                   commands:[dict objectForKey:@"commands"]];
  if (!self)
    return nil;
  return self;
}

#pragma mark Class methods

+ (void)_loadKeyboardActionsFromFileURL:(NSURL *)fileURL {
  if (!systemKeyboardActions)
    systemKeyboardActions = [NSMutableDictionary new];
  
  NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
  ASSERT(plist != nil);
  ASSERT([plist objectForKey:@"keyboardActionsConfiguration"] == nil); // No configurations allowed
  
  // Load global actions
  for (NSDictionary *action in [plist objectForKey:@"keyboardActions"]) {
    [systemKeyboardActions setObject:[[TMKeyboardAction alloc] initWithDictionary:action] forKey:[action objectForKey:@"uuid"]];
  }
}

+ (void)_loadKeyboardActionsConfigurationsFromFileURL:(NSURL *)fileURL {
  // Make sure that all keyboard actions have been loaded
  [self allKeyboardActions];
  
  NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
  ASSERT(plist != nil);
  
  // Load local actions
  NSMutableDictionary *localActions = [NSMutableDictionary new];
  for (NSDictionary *action in [plist objectForKey:@"keyboardActions"]) {
    [localActions setObject:[[TMKeyboardAction alloc] initWithDictionary:action] forKey:[action objectForKey:@"uuid"]];
  }
  
  // Load configuration
  NSMutableArray *configuration = [NSMutableArray new];
  for (NSString *actionUUID in [plist objectForKey:@"keyboardActionsConfiguration"])
  {
    if ([actionUUID length] == 0 || [actionUUID isEqualToString:@"inherit"]) {
      [configuration addObject:[NSNull null]];
    } else {
      // Get action from local or global action dictionaries
      id action = [localActions objectForKey:actionUUID];
      if (!action)
        action = [systemKeyboardActions objectForKey:actionUUID];
      [configuration addObject:action];
    }
  }
  
  // Add configuration to system list
  if (!systemKeyboardActionsConfigurations)
    systemKeyboardActionsConfigurations = [NSMutableDictionary new];
  for (NSString *scope in [[plist objectForKey:@"scope"] componentsSeparatedByString:@","])
  {
    [systemKeyboardActionsConfigurations setObject:[configuration copy] forKey:scope];
  }
}

+ (NSDictionary *)allKeyboardActions {
  if (!systemKeyboardActions) {
    for (NSURL *bundleURL in [TMBundle bundleURLs]) {
      for (NSURL *keyboardActionURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:keyboardActionsPath isDirectory:YES] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL]) {
        [self _loadKeyboardActionsFromFileURL:keyboardActionURL];
      }
    }
  }
  return systemKeyboardActions;
}

+ (NSArray *)defaultKeyboardActionsConfiguration {
  if (!systemDefaultKeyboardActionsConfiguration) {
    // TODO actually craete an hardcoded cofiguration
    systemDefaultKeyboardActionsConfiguration = [[self allKeyboardActionsConfigurations] objectForKey:@"text.plain"];
    ASSERT(systemDefaultKeyboardActionsConfiguration.count == 11);
  }
  return systemDefaultKeyboardActionsConfiguration;
}

+ (NSDictionary *)allKeyboardActionsConfigurations {
  if (!systemKeyboardActionsConfigurations) {
    NSNumber *isRegularFile = nil;
    for (NSURL *bundleURL in [TMBundle bundleURLs]) {
      for (NSURL *keyboardActionURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:keyboardConfigurationsPath isDirectory:YES] includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsRegularFileKey] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL]) {
        if ([keyboardActionURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:NULL] && [isRegularFile boolValue]) {
          [self _loadKeyboardActionsConfigurationsFromFileURL:keyboardActionURL];
        }
      }
    }
  }
  return systemKeyboardActionsConfigurations;
}

+ (NSArray *)keyboardActionsConfigurationForQualifiedIdentifier:(NSString *)qualifiedIdentifier {
  if (qualifiedIdentifier == nil)
    return [self defaultKeyboardActionsConfiguration];
  
  // Get all the configurations that repond to the selector
  NSMutableDictionary *configurationDictionary = [NSMutableDictionary new];
  [[self allKeyboardActionsConfigurations] enumerateKeysAndObjectsUsingBlock:^(NSString *scopeSelector, NSArray *conf, BOOL *stop) {
    float score = [qualifiedIdentifier scoreForScopeSelector:scopeSelector];
    if (score > 0) {
      [configurationDictionary setObject:conf forKey:[NSNumber numberWithFloat:score]];
    }
  }];
  
  // Get the base configuration
  NSMutableArray *configuration = [[self defaultKeyboardActionsConfiguration] mutableCopy];
  
  // Apply configurations
  if (configurationDictionary.count) {
    for (NSNumber *n in [[configurationDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
      [(NSArray *)[configurationDictionary objectForKey:n] enumerateObjectsUsingBlock:^(id action, NSUInteger idx, BOOL *stop) {
        if (action != [NSNull null]) {
          // If action is not inherit, substitute to result configuration
          [configuration removeObjectAtIndex:idx];
          [configuration insertObject:action atIndex:idx];
        }
      }];
    }
  }
  
  return [configuration copy];
}

@end
