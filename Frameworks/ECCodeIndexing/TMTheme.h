//
//  TMTheme.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMTheme : NSObject

/// The directory where theme files are saved
+ (NSURL *)themeDirectory;
+ (void)setThemeDirectory:(NSURL *)themeDirectory;

+ (NSArray *)themeNames;
+ (TMTheme *)themeWithName:(NSString *)name;

@property (nonatomic, strong, readonly) NSString *name;

- (NSDictionary *)attributesForScopeStack:(NSArray *)scopeStack;

@end
