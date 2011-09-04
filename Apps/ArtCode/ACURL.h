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
extern NSString * const ACProjectContentDirectory;

@interface NSURL (ACURL)

/// Returns the application's documents directory
+ (NSURL *)applicationDocumentsDirectory;

/// Returns the application's library directory
+ (NSURL *)applicationLibraryDirectory;

/// Returns whether or not the URL is an ACURL
- (BOOL)isACURL;

/// Returns whether the ACURL refers to a local resource
- (BOOL)isLocal;

/// Returns the local projects directory
+ (NSURL *)ACLocalProjectsDirectory;

/// Returns the name of the project which is referenced by or contains the node referenced by the ACURL
- (NSString *)ACProjectName;

/// Returns a file URL to the bundle of the project referenced by or containing the node referenced by the ACURL
- (NSURL *)ACProjectBundleURL;

/// Returns a file URL to the content directory of the project referenced by or containing the node referenced by the ACURL
- (NSURL *)ACProjectContentURL;

/// Returns an ACURL referencing a local project with the given name
+ (NSURL *)ACURLForLocalProjectWithName:(NSString *)name;

/// Create an ACURL referencing the node for the given path
+ (NSURL *)ACURLWithPath:(NSString *)path;

/// Returns whether the receiver references an ancestor of the object referenced by the passed ACURL
- (BOOL)isAncestorOfACURL:(NSURL *)URL;

/// Returns whether the receiver references a descendant of the object referenced by the passed ACURL
- (BOOL)isDescendantOfACURL:(NSURL *)URL;

@end
