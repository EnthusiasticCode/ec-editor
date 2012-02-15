//
//  TMBundle.h
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMBundle : NSObject

/// An array containing URLs for all bundles in the set bundle directory
+ (NSArray *)bundleURLs;

@end
