//
//  ACURL.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ACProjectBundleExtension;
extern NSString * const ACURLScheme;

@interface NSURL (ACURL)

/// Returns the application's documents directory
+ (NSURL *)applicationDocumentsDirectory;

/// Returns the application's library directory
+ (NSURL *)applicationLibraryDirectory;

/// Return a temporary directory
+ (NSURL *)temporaryDirectory;

/// Returns whether or not the URL is an ACURL
- (BOOL)isACURL;

/// Returns the ACURL of the project which contains the node referenced by the ACURL
- (NSURL *)ACProjectURL;

/// Create an ACURL referencing the node with the given path components
+ (NSURL *)ACURLWithPathComponents:(NSArray *)pathComponents;

/// Create an ACURL referencing the node for the given path
+ (NSURL *)ACURLWithPath:(NSString *)path;

/// Returns whether the receiver references an ancestor of the object referenced by the passed ACURL
- (BOOL)isAncestorOfACURL:(NSURL *)URL;

/// Returns whether the receiver references a descendant of the object referenced by the passed ACURL
- (BOOL)isDescendantOfACURL:(NSURL *)URL;

@end
