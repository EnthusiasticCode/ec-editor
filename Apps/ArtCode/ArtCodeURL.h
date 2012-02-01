//
//  ArtCodeURL.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ArtCodeProject;

@interface ArtCodeURL

/// Returns the URL in which projects are stored
+ (NSURL *)projectsDirectory;

/// Returns a path relative to the projects directory if the file is within it, nil otherwise.
+ (NSString *)pathRelativeToProjectsDirectory:(NSURL *)fileURL;

/// Gets the project name from an URL or nil if no project was found.
/// Uppon return, in isProjectRoot is not NULL, it will contain a value indicating if the given URL is a project root.
+ (NSString *)projectNameFromURL:(NSURL *)url isProjectRoot:(BOOL *)isProjectRoot;

@end

@interface NSURL (ArtCodeURL)

@property (readonly) ArtCodeProject *project;

/// Indicate if the URL has a bookmarks specifier.
- (BOOL)isBookmarksVariant;
- (NSURL *)URLByAddingBookmarksVariant;

/// Returns a string that has a pretty path format that removes '.weakpkg' extensions and adds ▸ instead of /
- (NSString *)prettyPathRelativeToProjectDirectory;

@end
