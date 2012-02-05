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

/// An array containing URLs for all bundles in the set bundle directory
+ (NSArray *)bundleURLs;

@end
