//
//  TMTheme.h
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
// We need this for CGFloat
#import <CoreText/CoreText.h>

extern NSString * const TMThemeBackgroundColorEnvironmentAttributeKey;
extern NSString * const TMThemeCaretColorEnvironmentAttributeKey;
extern NSString * const TMThemeForegroundColorEnvironmentAttributeKey;
extern NSString * const TMThemeLineHighlightColorEnvironmentAttributeKey;
extern NSString * const TMThemeSelectionColorEnvironmentAttributeKey;

@class TMScope;

@interface TMTheme : NSObject

/// Initialize a theme with the URL of it's .tmbundle file.
- (id)initWithFileURL:(NSURL *)url;

/// The name of the theme
@property (nonatomic, strong, readonly) NSString *name;

/// Gets an attribute dictinary with settings of the environment for the theme.
/// See TMThemeEnvironmentAttribute keys. Values are UIKit objects like UIColor.
- (NSDictionary *)environmentAttributes;

/// A dictionary containing the font and foreground color for the theme.
/// This methods uses the shared font attributes.
- (NSDictionary *)commonAttributes;

/// Returns an array of Core Text attributes applicable to an NSAttributedString for the given scope.
- (NSDictionary *)attributesForScope:(TMScope *)scope;

#pragma mark Default styles

/// Creates a theme from a name and bundle.
+ (TMTheme *)themeWithName:(NSString *)name bundle:(NSBundle *)bundle;

/// Returns a dictionary containing the default attributes of a string, common to every theme item.
+ (NSDictionary *)sharedAttributes;

/// Sets the font that shared attributes will return as a text attribute.
+ (void)setSharedFontName:(NSString *)fontName size:(CGFloat)pointSize;

@end
