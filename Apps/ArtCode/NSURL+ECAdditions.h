//
//  ACURL.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSURL.h>

@interface NSURL (ECAdditions)

/// Returns the application's documents directory
+ (NSURL *)applicationDocumentsDirectory;

/// Returns the application's library directory
+ (NSURL *)applicationLibraryDirectory;

/// Return a temporary directory
+ (NSURL *)temporaryDirectory;

/// Returns whether the receiver is a descendant of a subdirectory of the given directory
- (BOOL)isSubdirectoryDescendantOfDirectoryAtURL:(NSURL *)directoryURL;

/// Returns whether the receiver refers to a hidden file
- (BOOL)isHidden;
- (BOOL)isHiddenDescendant;

/// Returns whether the receiver refers to a package
- (BOOL)isPackage;
- (BOOL)isPackageDescendant;

- (NSURL *)URLByAppendingFragmentDictionary:(NSDictionary *)fragmentDictionary;
- (NSDictionary *)fragmentDictionary;

@end
