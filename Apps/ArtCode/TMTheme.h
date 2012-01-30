//
//  TMTheme.h
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TMTheme : NSObject

/// Initialize a theme with the URL of it's .tmbundle file.
- (id)initWithFileURL:(NSURL *)url;

/// The name of the theme
@property (nonatomic, strong, readonly) NSString *name;

/// Returns an array of Core Text attributes applicable to an NSAttributedString for the given scope.
/// Optionally provide a scope stack to match nested scope rules
- (NSDictionary *)attributesForScopeIdentifier:(NSString *)scopeIdentifier withStack:(NSArray *)scopeIdentifiersStack;

#pragma mark Default styles

/// Creates a theme from a name and bundle.
+ (TMTheme *)themeWithName:(NSString *)name bundle:(NSBundle *)bundle;

/// Returns a dictionary containing the default attributes of a string, common to every theme item.
+ (NSDictionary *)defaultAttributes;

@end
