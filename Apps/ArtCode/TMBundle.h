//
//  TMBundle.h
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMBundle : NSObject

/// The directory where language bundles are saved, defaults to the application's main bundle directory
+ (NSURL *)bundleDirectory;
+ (void)setBundleDirectory:(NSURL *)bundleDirectory;

/// An array containing all the bundles
+ (NSArray *)allBundles;

/// The bundle's name
- (NSString *)name;

/// An array containing all the bundle's syntaxes
- (NSArray *)syntaxes;

@end
