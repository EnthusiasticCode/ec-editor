//
//  TMPreferences.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


// Indicates if the scope should be shown in the symbol list. This value returns an NSValue with a bool. The bool is true even if this key is not found but TMPreferenceSymbolTransformationKey is set for the same selector.
extern NSString * const TMPreferenceShowInSymbolListKey;
// Returns a block that gets a string as a parameter and returns a transformed string.
extern NSString * const TMPreferenceSymbolTransformationKey;
// Returns a UIImage.
extern NSString * const TMPreferenceSymbolIconKey;
// Returns an NSNumber with a boolean value indicating if the symbols should be rendered as a separator.
extern NSString * const TMPreferenceSymbolIsSeparatorKey;
// Returns an NSDictionary of string to pair string.
extern NSString * const TMPreferenceSmartTypingPairsKey;
// Returns a blok (NSString * -> bool) that returns if the line should increment the indetation
extern NSString * const TMPreferenceIncreaseIndentKey;
extern NSString * const TMPreferenceDecreaseIndentKey;
extern NSString * const TMPreferenceIndentNextLineKey;


// Load and present all the preferences of a textmate bundle. 
// Preferences are stored in a per scope selector base.
@interface TMPreference : NSObject

#pragma mark Accessing preference definition

// The scope selector that indicates which scopes are affected by this preference.
@property (nonatomic, strong, readonly) NSString *scopeSelector;

// Get the preference value fot the given key.
- (id)preferenceValueForKey:(NSString *)key;

#pragma mark Creating a new preference

- (id)initWithScopeSelector:(NSString *)scope settingsDictionary:(NSDictionary *)settingsDict;

#pragma mark Retrieving preferences

// Returns a dictionary that maps scope selector to it's TMPreference.
// The dictionary contains all the loaded preferences from the found bundles.
+ (NSDictionary *)allPreferences;

// Returns the specified preference's value for the scope. 
+ (id)preferenceValueForKey:(NSString *)preferenceKey qualifiedIdentifier:(NSString *)qualifiedIdentifier;

#pragma mark Symbol Icons

// Returns a generated image based on the symbol identifier. Common identifiers are Function, Method, Class.
+ (UIImage *)symbolIconForIdentifier:(NSString *)symbolIdentifier;

@end


@interface TMPreference (Forwarding)

// The count of preference values.
- (NSUInteger)count;

@end
