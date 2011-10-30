//
//  TMTheme.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const TMThemeBackgroundColorAttributeName;
extern NSString *const TMThemeFontStyleAttributeName;

@interface TMTheme : NSObject

+ (TMTheme *)themeWithName:(NSString *)name bundle:(NSBundle *)bundle;

- (id)initWithFileURL:(NSURL *)url;

/// Returns an array of Core Text attributes applicable to an NSAttributedString for the given scopes stack.
- (NSDictionary *)attributesForScopeStack:(NSArray *)scopesStack;

@property (nonatomic, strong, readonly) NSString *name;

@end
