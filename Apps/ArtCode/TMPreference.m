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

NSString * const TMPreferenceShowInSymbolListKey = @"showInSymbolList";
NSString * const TMPreferenceSymbolTransformationKey = @"symbolTransformation";

/// Dictionary of scope selector to TMPreference
static NSDictionary * systemTMPreferencesDictionary;
static NSMutableDictionary *scopeToPreferenceCache;

@implementation TMPreference

#pragma mark - Properties

@synthesize scopeSelector, settings;

#pragma mark - Initialization

- (id)initWithScopeSelector:(NSString *)scope settingsDictionary:(NSDictionary *)settingsDict
{
    ECASSERT([settingsDict count] != 0);
    self = [super init];
    if (!self)
        return nil;
    scopeSelector = scope;
    // Preprocessing setting dictionary
    NSMutableDictionary *preprocessedSettings = [NSMutableDictionary new];
    [settingsDict enumerateKeysAndObjectsUsingBlock:^(NSString *settingName, id value, BOOL *stop) {
        if ([settingName isEqualToString:TMPreferenceShowInSymbolListKey])
        {
            [preprocessedSettings setObject:value forKey:TMPreferenceShowInSymbolListKey];
        }
        else if ([settingName isEqualToString:TMPreferenceSymbolTransformationKey])
        {
            // Set showInSymbolList if not set
            if (![settingsDict objectForKey:TMPreferenceShowInSymbolListKey])
                [preprocessedSettings setObject:[NSNumber numberWithBool:YES] forKey:TMPreferenceShowInSymbolListKey];
            // Prepare transformations regexps
//            preprocessedSettings setObject:[] forKey:<#(id)#>
        }
    }];
    settings = [preprocessedSettings copy];
    return self;
}

#pragma mark - Class methods

+ (NSDictionary *)allPreferences
{
    if (!systemTMPreferencesDictionary)
    {
        NSMutableDictionary *preferences = [NSMutableDictionary new];
        for (NSURL *bundleURL in [TMBundle bundleURLs])
        {
            for (NSURL *preferenceURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:@"Preferences" isDirectory:YES] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
            {
                NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:preferenceURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
                ECASSERT(plist != nil && "Couldn't load plist");
                NSString *scopeSelector = [plist objectForKey:@"scope"];
                if (!scopeSelector)
                    continue;
                TMPreference *pref = [[TMPreference alloc] initWithScopeSelector:scopeSelector settingsDictionary:[plist objectForKey:@"settings"]];
                if ([pref.settings count] == 0)
                    continue;
                [preferences setObject:pref forKey:scopeSelector];
            }
        }
        systemTMPreferencesDictionary = [preferences copy];
    }
    return systemTMPreferencesDictionary;
}

+ (id)preferenceValueForKey:(NSString *)preferenceKey scope:(TMScope *)scope
{
    if (!scopeToPreferenceCache)
        scopeToPreferenceCache = [NSMutableDictionary new];
    NSMutableDictionary *cachedPreferences = [scopeToPreferenceCache objectForKey:scope.qualifiedIdentifier];
    __block id value = [cachedPreferences objectForKey:preferenceKey];
    if (value)
        return value == [NSNull null] ? nil : value;
    
    [[self allPreferences] enumerateKeysAndObjectsUsingBlock:^(NSString *scopeSelector, TMPreference *preference, BOOL *stop) {
        if ([scope scoreForScopeSelector:scopeSelector] > 0 && (value = [preference.settings objectForKey:preferenceKey]))
            *stop = YES;
    }];
    
    if (!cachedPreferences)
    {
        cachedPreferences = [NSMutableDictionary new];
        [scopeToPreferenceCache setObject:cachedPreferences forKey:scope.qualifiedIdentifier];
    }
    [cachedPreferences setObject:value ? value : [NSNull null] forKey:preferenceKey];
    
    return value;
}

@end
