//
//  ACURL.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ACURLScheme;

@interface NSURL (ACURL)

/// Returns whether or not the URL is an ACURL
- (BOOL)isACURL;

/// Returns the ACURL of the project which contains the object referenced by the ACURL
- (NSURL *)ACProjectURL;

/// Returns the name of the project which contains the object referenced by the ACURL
- (NSString *)ACProjectName;

/// Returns whether or not the ACURL refers to a project
- (BOOL)isACProjectURL;

/// Create an ACURL referencing the object with the given path components
+ (NSURL *)ACURLWithPathComponents:(NSArray *)pathComponents;

/// Create an ACURL referencing the object for the given path
+ (NSURL *)ACURLWithPath:(NSString *)path;

/// Returns whether the receiver references an ancestor of the object referenced by the passed ACURL
- (BOOL)isAncestorOfACURL:(NSURL *)URL;

/// Returns whether the receiver references a descendant of the object referenced by the passed ACURL
- (BOOL)isDescendantOfACURL:(NSURL *)URL;

@end
