//
//  TMPreferences.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMPreference.h"
#import "TMBundle.h"
#import "NSString+TextMateScopeSelectorMatching.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "UIImage+AppStyle.h"

NSString * const TMPreferenceShowInSymbolListKey = @"showInSymbolList";
NSString * const TMPreferenceSymbolTransformationKey = @"symbolTransformation";
NSString * const TMPreferenceSymbolIconKey = @"symbolIcon";
NSString * const TMPreferenceSymbolIsSeparatorKey = @"symbolIsSeparator";
NSString * const TMPreferenceSmartTypingPairsKey = @"smartTypingPairs";

/// Dictionary of scope selector to TMPreference
static NSDictionary * systemTMPreferencesDictionary;
static TMPreference *systemGlobalPreferences;
static NSMutableDictionary *scopeToPreferenceCache;
static NSMutableDictionary *symbolIconsCache;

@interface TMPreference ()

- (void)_addSettingsDictionary:(NSDictionary *)settingsDictionary;
- (NSString*(^)(NSString *))_createBlockForSymbolTransformation:(NSString *)transformation;

@end

@interface TMPreferenceSymbolTransformation : NSObject {
@public
  OnigRegexp *regExp;
  NSString *templateString;
  BOOL isGlobal;
}

- (id)initWithRegExp:(OnigRegexp *)exp template:(NSString *)temp isGlobal:(BOOL)glob;

@end

@implementation TMPreference {
  NSMutableDictionary *_settings;
}

#pragma mark - Properties

@synthesize scopeSelector;

#pragma mark - Initialization

- (id)initWithScopeSelector:(NSString *)scope settingsDictionary:(NSDictionary *)settingsDict
{
  ASSERT([settingsDict count] != 0);
  self = [super init];
  if (!self)
    return nil;
  scopeSelector = scope;
  // Preprocessing setting dictionary
  [self _addSettingsDictionary:settingsDict];
  return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  if (aSelector == @selector(count))
    return _settings;
  return nil;
}

- (id)preferenceValueForKey:(NSString *)key
{
  return [_settings objectForKey:key];
}

#pragma mark - Class methods

+ (void)initialize
{
  if (self != [TMPreference class])
    return;
  // This class takes a long time to initialize, we have to make sure it doesn't do so on the main queue
#if ! TEST
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
#endif
  NSMutableDictionary *preferences = [NSMutableDictionary new];
  for (NSURL *bundleURL in [TMBundle bundleURLs])
  {
    for (NSURL *preferenceURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:@"Preferences" isDirectory:YES] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
    {
      NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:preferenceURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
      ASSERT(plist != nil && "Couldn't load plist");
      
      // Get preference objects
      NSString *scopeSelector = [plist objectForKey:@"scope"];
      NSDictionary *settings = [plist objectForKey:@"settings"];
      if (scopeSelector) {
        // Add scope specific preferences
        TMPreference *pref = [preferences objectForKey:scopeSelector];
        if (!pref) {
          pref = [[TMPreference alloc] initWithScopeSelector:scopeSelector settingsDictionary:settings];
        } else {
          [pref _addSettingsDictionary:settings];
        }
        // Add preferences to global dictionary if any is present
        if ([pref count] != 0) {
          [preferences setObject:pref forKey:scopeSelector];
        }
      } else {
        // Getting supported global settings
        if (!systemGlobalPreferences) {
          systemGlobalPreferences = [[TMPreference alloc] initWithScopeSelector:@"*" settingsDictionary:settings];
        } else {
          [systemGlobalPreferences _addSettingsDictionary:settings];
        }
      }
    }
  }
  systemTMPreferencesDictionary = [preferences copy];
}

+ (NSDictionary *)allPreferences
{
  return systemTMPreferencesDictionary;
}

+ (id)preferenceValueForKey:(NSString *)preferenceKey qualifiedIdentifier:(NSString *)qualifiedIdentifier
{
  // Check per scope cache
  if (!scopeToPreferenceCache)
    scopeToPreferenceCache = [NSMutableDictionary new];
  NSMutableDictionary *cachedPreferences = [scopeToPreferenceCache objectForKey:qualifiedIdentifier];
  __block id value = [cachedPreferences objectForKey:preferenceKey];
  if (value)
    return value == [NSNull null] ? nil : value;
  
  // Get required preference value
  __block float highestScore = 0;
  __block TMPreference *selectedPreference = nil;
  [[self allPreferences] enumerateKeysAndObjectsUsingBlock:^(NSString *scopeSelector, TMPreference *preference, BOOL *stop) {
    float score = [qualifiedIdentifier scoreForScopeSelector:scopeSelector];
    if (score > highestScore && (value = [selectedPreference preferenceValueForKey:preferenceKey])) {
      highestScore = score;
    }
  }];
  
  // With no found value, trying the global preferences
  if (!value) {
    value = [systemGlobalPreferences preferenceValueForKey:preferenceKey];
  }
  
  // Cache resulting coalesed preferences per scope
  if (!cachedPreferences) {
    cachedPreferences = [NSMutableDictionary new];
    [scopeToPreferenceCache setObject:cachedPreferences forKey:qualifiedIdentifier];
  }
  [cachedPreferences setObject:value ?: [NSNull null] forKey:preferenceKey];
  
  return value;
}

+ (UIImage *)symbolIconForIdentifier:(NSString *)symbolIdentifier {
  UIImage *icon = [symbolIconsCache objectForKey:symbolIdentifier];
  if (!icon) {
    NSString *letter = [symbolIdentifier substringToIndex:1];
    UIColor *color = [UIColor lightGrayColor];
    if ([symbolIdentifier isEqualToString:@"Class"]) {
      color = [UIColor colorWithRed:.62 green:.54 blue:.73 alpha:1];
    } else if ([symbolIdentifier isEqualToString:@"Method"]) {
      color = [UIColor colorWithRed:.32 green:.46 blue:.73 alpha:1];
    } else if ([symbolIdentifier isEqualToString:@"Function"]) {
      letter = @"f";
      color = [UIColor colorWithRed:.46 green:.64 blue:.53 alpha:1];
    } else if ([symbolIdentifier isEqualToString:@"Preprocessor"]) {
      letter = @"#";
      color = [UIColor colorWithRed:.75 green:.46 blue:.46 alpha:1];
    }
    // Generate the image
    icon = [UIImage styleSymbolImageWithSize:CGSizeMake(16, 16) color:color letter:letter];
    // Cache the result
    if (!symbolIconsCache) {
      symbolIconsCache = [[NSMutableDictionary alloc] init];
    }
    [symbolIconsCache setObject:icon forKey:symbolIdentifier];
  }
  return icon;
}

#pragma mark - Private Methods

- (void)_addSettingsDictionary:(NSDictionary *)settingsDict
{
  if (!_settings)
    _settings = [NSMutableDictionary new];
  [settingsDict enumerateKeysAndObjectsUsingBlock:^(NSString *settingName, id value, BOOL *stop) {
    
    // Symbol list
    if ([settingName isEqualToString:TMPreferenceShowInSymbolListKey]) {
      [_settings setObject:value forKey:TMPreferenceShowInSymbolListKey];
    }
    
    // Symbol transformation
    else if ([settingName isEqualToString:TMPreferenceSymbolTransformationKey]) {
      // Set showInSymbolList if not set
      if (![settingsDict objectForKey:TMPreferenceShowInSymbolListKey])
        [_settings setObject:[NSNumber numberWithBool:YES] forKey:TMPreferenceShowInSymbolListKey];
      // Prepare transformations regexps
      [_settings setObject:[self _createBlockForSymbolTransformation:value] forKey:TMPreferenceSymbolTransformationKey];
    }
    
    // Symbol Icon
    else if ([settingName isEqualToString:TMPreferenceSymbolIconKey]) {
      // Load or generate an image for the symbol
      UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"symbolIcon_%@", value]];
      if (!image) {
        image = [[self class] symbolIconForIdentifier:value];
      }
      [_settings setObject:image forKey:TMPreferenceSymbolIconKey];
      // TODO also use symbolImagePath, symbolImageColor & Title
    }

    // Symbol separation
    else if ([settingName isEqualToString:TMPreferenceSymbolIsSeparatorKey]) {
      [_settings setObject:value forKey:TMPreferenceSymbolIsSeparatorKey];
    }
    
    // Smart typing pairs
    else if ([settingName isEqualToString:TMPreferenceSmartTypingPairsKey]) {
      ASSERT([_settings objectForKey:TMPreferenceSmartTypingPairsKey] == nil); // In this case the array should get mutable
      NSMutableDictionary *pairs = [NSMutableDictionary new];
      for (NSArray *pairArray in value) {
        [pairs setObject:[pairArray objectAtIndex:1] forKey:[pairArray objectAtIndex:0]];
      }
      [_settings setObject:pairs forKey:TMPreferenceSmartTypingPairsKey];
    }
  }];
}

- (NSString *(^)(NSString *))_createBlockForSymbolTransformation:(NSString *)transformation
{
  // Regular expression that find matches in other regular expressions formed as
  static NSRegularExpression *transformationSplitter = nil;
  if (!transformationSplitter)
    transformationSplitter = [NSRegularExpression regularExpressionWithPattern:@"s/(.*?[^\\\\])/(.*?[^\\\\]?)/(g?)" options:0 error:NULL];
  
  // Search transformations
  NSMutableArray *transformations = [NSMutableArray new];
  [transformationSplitter enumerateMatchesInString:transformation options:0 range:NSMakeRange(0, [transformation length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    ASSERT([result numberOfRanges] == 4);
    [transformations addObject:[[TMPreferenceSymbolTransformation alloc] initWithRegExp:[OnigRegexp compile:[transformation substringWithRange:[result rangeAtIndex:1]] options:OnigOptionCaptureGroup] template:[transformation substringWithRange:[result rangeAtIndex:2]] isGlobal:[[transformation substringWithRange:[result rangeAtIndex:3]] length]]];
  }];
  
  // Create block
  return [^NSString *(NSString *symbol) {
    NSMutableString *result = [symbol mutableCopy];
    for (TMPreferenceSymbolTransformation *t in transformations) {
      if (t->isGlobal)
        [t->regExp gsub:result string:t->templateString];
      else
        [t->regExp sub:result string:t->templateString];
    }
    return result;
  } copy];
}

@end

@implementation TMPreferenceSymbolTransformation

- (id)initWithRegExp:(OnigRegexp *)exp template:(NSString *)temp isGlobal:(BOOL)glob
{
  self = [super init];
  if (!self)
    return nil;
  regExp = exp;
  templateString = temp;
  isGlobal = glob;
  return self;
}

@end
