
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
NSString * const TMPreferenceIncreaseIndentKey = @"increaseIndentPattern";
NSString * const TMPreferenceDecreaseIndentKey = @"decreaseIndentPattern";
NSString * const TMPreferenceIndentNextLineKey = @"indentNextLinePattern";

/// Dictionary of scope selector to TMPreference
static NSDictionary * systemTMPreferencesDictionary;
static TMPreference *systemGlobalPreferences;
static NSMutableDictionary *scopeToPreferenceCache;
static NSMutableDictionary *symbolIconsCache;


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
  return _settings[key];
}

#pragma mark - Class methods

+ (void)initialize
{
  if (self != [TMPreference class])
    return;
  // This class takes a long time to initialize, we have to make sure it doesn't do so on the main queue
#if ! TEST
//  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
#endif
  NSMutableDictionary *preferences = [[NSMutableDictionary alloc] init];
  for (NSURL *bundleURL in [TMBundle bundleURLs])
  {
    for (NSURL *preferenceURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:@"Preferences" isDirectory:YES] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
    {
      NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:preferenceURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
      ASSERT(plist != nil && "Couldn't load plist");
      
      // Get preference objects
      NSString *scopeSelector = plist[@"scope"];
      NSDictionary *settings = plist[@"settings"];
      if (scopeSelector) {
        // Add scope specific preferences
        TMPreference *pref = preferences[scopeSelector];
        if (!pref) {
          pref = [[TMPreference alloc] initWithScopeSelector:scopeSelector settingsDictionary:settings];
        } else {
          [pref _addSettingsDictionary:settings];
        }
        // Add preferences to global dictionary if any is present
        if ([pref count] != 0) {
          preferences[scopeSelector] = pref;
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
  if (!qualifiedIdentifier || !preferenceKey) {
    return nil;
  }
  // Check per scope cache
  if (!scopeToPreferenceCache)
    scopeToPreferenceCache = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *cachedPreferences = scopeToPreferenceCache[qualifiedIdentifier];
  __block id value = cachedPreferences[preferenceKey];
  if (value)
    return value == [NSNull null] ? nil : value;
  
  
  // Get required preference value
  __block float highestScore = 0;
  [[self allPreferences] enumerateKeysAndObjectsUsingBlock:^(NSString *scopeSelector, TMPreference *preference, BOOL *stop) {
    float score = [qualifiedIdentifier scoreForScopeSelector:scopeSelector];
    if (score > highestScore && (value = [preference preferenceValueForKey:preferenceKey])) {
      highestScore = score;
    }
  }];
  
  // With no found value, trying the global preferences
  if (!value) {
    value = [systemGlobalPreferences preferenceValueForKey:preferenceKey];
  }
  
  // Cache resulting coalesed preferences per scope
  if (!cachedPreferences) {
    cachedPreferences = [[NSMutableDictionary alloc] init];
    scopeToPreferenceCache[qualifiedIdentifier] = cachedPreferences;
  }
  cachedPreferences[preferenceKey] = value ?: [NSNull null];
  
  return value;
}

+ (UIImage *)symbolIconForIdentifier:(NSString *)symbolIdentifier {
  UIImage *icon = symbolIconsCache[symbolIdentifier];
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
    symbolIconsCache[symbolIdentifier] = icon;
  }
  return icon;
}

#pragma mark - Private Methods

- (void)_addSettingsDictionary:(NSDictionary *)settingsDict
{
  if (!_settings)
    _settings = [[NSMutableDictionary alloc] init];
  [settingsDict enumerateKeysAndObjectsUsingBlock:^(NSString *settingName, id value, BOOL *stop) {
    
    // Symbol list
    if ([settingName isEqualToString:TMPreferenceShowInSymbolListKey]) {
      _settings[TMPreferenceShowInSymbolListKey] = value;
    }
    
    // Symbol transformation
    else if ([settingName isEqualToString:TMPreferenceSymbolTransformationKey]) {
      // Set showInSymbolList if not set
      if (!settingsDict[TMPreferenceShowInSymbolListKey])
        _settings[TMPreferenceShowInSymbolListKey] = @YES;
      // Prepare transformations regexps
      _settings[TMPreferenceSymbolTransformationKey] = [self _createBlockForSymbolTransformation:value];
    }
    
    // Symbol Icon
    else if ([settingName isEqualToString:TMPreferenceSymbolIconKey]) {
      // Load or generate an image for the symbol
      UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"symbolIcon_%@", value]];
      if (!image) {
        image = [[self class] symbolIconForIdentifier:value];
      }
      _settings[TMPreferenceSymbolIconKey] = image;
      // TODO: also use symbolImagePath, symbolImageColor & Title
    }

    // Symbol separation
    else if ([settingName isEqualToString:TMPreferenceSymbolIsSeparatorKey]) {
      _settings[TMPreferenceSymbolIsSeparatorKey] = value;
    }
    
    // Smart typing pairs
    else if ([settingName isEqualToString:TMPreferenceSmartTypingPairsKey]) {
      ASSERT([_settings objectForKey:TMPreferenceSmartTypingPairsKey] == nil); // In this case the array should get mutable
      NSMutableDictionary *pairs = [[NSMutableDictionary alloc] init];
      for (NSArray *pairArray in value) {
        pairs[pairArray[0]] = pairArray[1];
      }
      _settings[TMPreferenceSmartTypingPairsKey] = pairs;
    }
    
    // Indentation
    else if ([settingName isEqualToString:TMPreferenceIncreaseIndentKey]) {
      _settings[TMPreferenceIncreaseIndentKey] = [self _createBlockForIndentPattern:value];
    }
    else if ([settingName isEqualToString:TMPreferenceDecreaseIndentKey]) {
      _settings[TMPreferenceDecreaseIndentKey] = [self _createBlockForIndentPattern:value];
    }
    else if ([settingName isEqualToString:TMPreferenceIndentNextLineKey]) {
      _settings[TMPreferenceIndentNextLineKey] = [self _createBlockForIndentPattern:value];
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
  NSMutableArray *transformations = [[NSMutableArray alloc] init];
  [transformationSplitter enumerateMatchesInString:transformation options:0 range:NSMakeRange(0, [transformation length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    ASSERT([result numberOfRanges] == 4);
    [transformations addObject:[[TMPreferenceSymbolTransformation alloc] initWithRegExp:[OnigRegexp compile:[transformation substringWithRange:[result rangeAtIndex:1]] options:OnigOptionCaptureGroup] template:[transformation substringWithRange:[result rangeAtIndex:2]] isGlobal:[[transformation substringWithRange:[result rangeAtIndex:3]] length]]];
  }];
  
  // Create block
  return [^NSString *(NSString *symbol) {
    for (TMPreferenceSymbolTransformation *t in transformations) {
      if (t->isGlobal) {
				symbol = [symbol replaceAllByRegexp:t->regExp with:t->templateString];
			} else {
				symbol = [symbol replaceByRegexp:t->regExp with:t->templateString];
			}
		}
		return symbol;
  } copy];
}

- (bool(^)(NSString*))_createBlockForIndentPattern:(NSString *)pattern {
  OnigRegexp *patternRegexp = [OnigRegexp compile:pattern];
  return [^bool(NSString *line) {
    // TODO: use a direct boolean method?
    return [[patternRegexp match:line] count] > 0;
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
