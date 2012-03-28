//
//  TMPreferences.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMPreference.h"
#import "TMBundle.h"
#import "TMScope.h"
#import <CocoaOniguruma/OnigRegexp.h>

NSString * const TMPreferenceShowInSymbolListKey = @"showInSymbolList";
NSString * const TMPreferenceSymbolTransformationKey = @"symbolTransformation";
NSString * const TMPreferenceSymbolIconKey = @"symbolIcon";
NSString * const TMPreferenceSymbolIsSeparatorKey = @"symbolIsSeparator";

/// Dictionary of scope selector to TMPreference
static NSDictionary * systemTMPreferencesDictionary;
static NSMutableDictionary *scopeToPreferenceCache;

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
    id value = [_settings objectForKey:key];
    if (key == TMPreferenceSymbolIconKey && [value isKindOfClass:[NSString class]])
    {
        // Convert symbol image from path to image when needed
        value = [UIImage imageWithContentsOfFile:(NSString *)value];
        [_settings setObject:value forKey:key];
    }
    return value;
}

#pragma mark - Class methods

+ (void)initialize
{
    if (self != [TMPreference class])
        return;
    // This class takes a long time to initialize, we have to make sure it doesn't do so on the main queue
    ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
    NSMutableDictionary *preferences = [NSMutableDictionary new];
    for (NSURL *bundleURL in [TMBundle bundleURLs])
    {
        for (NSURL *preferenceURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:@"Preferences" isDirectory:YES] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
        {
            NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:preferenceURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
            ASSERT(plist != nil && "Couldn't load plist");
            NSString *scopeSelector = [plist objectForKey:@"scope"];
            if (!scopeSelector)
                continue;
            TMPreference *pref = [preferences objectForKey:scopeSelector];
            if (!pref)
                pref = [[TMPreference alloc] initWithScopeSelector:scopeSelector settingsDictionary:[plist objectForKey:@"settings"]];
            else
                [pref _addSettingsDictionary:[plist objectForKey:@"settings"]];
            if ([pref count] == 0)
                continue;
            [preferences setObject:pref forKey:scopeSelector];
        }
    }
    systemTMPreferencesDictionary = [preferences copy];
}

+ (NSDictionary *)allPreferences
{
    return systemTMPreferencesDictionary;
}

+ (id)preferenceValueForKey:(NSString *)preferenceKey scope:(TMScope *)scope
{
    // Check per scope cache
    if (!scopeToPreferenceCache)
        scopeToPreferenceCache = [NSMutableDictionary new];
    NSMutableDictionary *cachedPreferences = [scopeToPreferenceCache objectForKey:scope.qualifiedIdentifier];
    __block id value = [cachedPreferences objectForKey:preferenceKey];
    if (value)
        return value == [NSNull null] ? nil : value;
    
    // Get required preference value
    [[self allPreferences] enumerateKeysAndObjectsUsingBlock:^(NSString *scopeSelector, TMPreference *preference, BOOL *stop) {
        if ([scope scoreForScopeSelector:scopeSelector] > 0 && (value = [preference preferenceValueForKey:preferenceKey]))
            *stop = YES;
    }];
    
    // Cache resulting coalesed preferences per scope
    if (!cachedPreferences)
    {
        cachedPreferences = [NSMutableDictionary new];
        [scopeToPreferenceCache setObject:cachedPreferences forKey:scope.qualifiedIdentifier];
    }
    [cachedPreferences setObject:value ? value : [NSNull null] forKey:preferenceKey];
    
    return value;
}

#pragma mark - Private Methods

- (void)_addSettingsDictionary:(NSDictionary *)settingsDict
{
    if (!_settings)
        _settings = [NSMutableDictionary new];
    [settingsDict enumerateKeysAndObjectsUsingBlock:^(NSString *settingName, id value, BOOL *stop) {
        if ([settingName isEqualToString:TMPreferenceShowInSymbolListKey])
        {
            [_settings setObject:value forKey:TMPreferenceShowInSymbolListKey];
        }
        else if ([settingName isEqualToString:TMPreferenceSymbolTransformationKey])
        {
            // Set showInSymbolList if not set
            if (![settingsDict objectForKey:TMPreferenceShowInSymbolListKey])
                [_settings setObject:[NSNumber numberWithBool:YES] forKey:TMPreferenceShowInSymbolListKey];
            // Prepare transformations regexps
            [_settings setObject:[self _createBlockForSymbolTransformation:value] forKey:TMPreferenceSymbolTransformationKey];
        }
        else if ([settingName isEqualToString:TMPreferenceSymbolIconKey])
        {
            value = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"symbolIcon_%@", value] ofType:@"png"];
            [_settings setObject:value forKey:TMPreferenceSymbolIconKey];
            // TODO also use symbolImagePath, symbolImageColor & Title
        }
        else if ([settingName isEqualToString:TMPreferenceSymbolIsSeparatorKey])
        {
            [_settings setObject:value forKey:TMPreferenceSymbolIsSeparatorKey];
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
