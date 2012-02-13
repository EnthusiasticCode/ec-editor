//
//  TMPreferences.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMScope;

/// Indicates if the scope should be shown in the symbol list. This value returns an NSValue with a bool. The bool is true even if this key is not found but TMPreferenceSymbolTransformationKey is set for the same selector.
extern NSString * const TMPreferenceShowInSymbolListKey;
/// Returns an NSRegularExpression
extern NSString * const TMPreferenceSymbolTransformationKey;


/// Load and present all the preferences of a textmate bundle. 
/// Preferences are stored in a per scope selector base.
@interface TMPreference : NSObject

+ (void)preload;

#pragma mark Accessing preference definition

/// The scope selector that indicates which scopes are affected by this preference.
@property (nonatomic, strong, readonly) NSString *scopeSelector;

/// A dictionary of preference key to values. See TMPreferenceKeys.
@property (nonatomic, strong, readonly) NSDictionary *settings;

#pragma mark Creating a new preference

- (id)initWithScopeSelector:(NSString *)scope settingsDictionary:(NSDictionary *)settingsDict;

#pragma mark Retrieving preferences

/// Returns a dictionary that maps scope selector to it's TMPreference.
/// The dictionary contains all the loaded preferences from the found bundles.
+ (NSDictionary *)allPreferences;

/// Returns the specified preference's value for the scope. 
+ (id)preferenceValueForKey:(NSString *)preferenceKey scope:(TMScope *)scope;

// TODO
+ (void)preapareForBackground;

@end
