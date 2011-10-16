//
//  TMBundle.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMBundle : NSObject

/// The directory where language bundles are saved
+ (NSURL *)bundleDirectory;
+ (void)setBundleDirectory:(NSURL *)bundleDirectory;

+ (NSArray *)bundleNames;
+ (TMBundle *)bundleWithName:(NSString *)bundleName;

@end
