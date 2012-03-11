//
//  ArtCodeURL.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACProject, ACProjectItem;

extern NSString * const artCodeURLProjectListPath;
extern NSString * const artCodeURLProjectBookmarkListPath;
extern NSString * const artCodeURLProjectRemoteListPath;

/// ArtCodeURL is encoded as follow:
/// artcode://projects                          -- project list
/// artcode://<project uuid>/bookmarks          -- project's bookmark list
/// artcode://<project uuid>/remotes            -- project's remote list
/// artcode://<project uuid>-<item uuid>/path   -- generic project, project item URL
@interface ArtCodeURL

/// Create a new NSURL encoding the project, project's item and path.
/// See const paths to generate lists variant.
/// ie: artCodeURLWithProject:nil item:nil path:artCodeURLProjectListPath; generates artcode://projects
+ (NSURL *)artCodeURLWithProject:(ACProject *)project item:(ACProjectItem *)item path:(NSString *)path;

////////////////////////////////////////////////////// TODO remove methods below this point

/// Returns the URL in which projects are stored
+ (NSURL *)projectsDirectory;

/// Returns a path relative to the projects directory if the file is within it, nil otherwise.
+ (NSString *)pathRelativeToProjectsDirectory:(NSURL *)fileURL;

/// Gets the project name from an URL or nil if no project was found.
/// Uppon return, in isProjectRoot is not NULL, it will contain a value indicating if the given URL is a project root.
+ (NSString *)projectNameFromURL:(NSURL *)url isProjectRoot:(BOOL *)isProjectRoot;

@end

@interface NSURL (ArtCodeURL)

/// Returns YES if the URL has an ArtCode scheme
- (BOOL)isArtCodeURL;

/// Indicates if the URL points to the global projects list
/// ie: the URL is in the format artcode://projects
- (BOOL)isArtCodeProjectsList;

/// Indicates if the URL points to a projects' bookmark list
/// ie: the URL is in the format artcode://<project uuid>/bookmarks
- (BOOL)isArtCodeProjectBookmarksList;

/// Indicates if the URL points to a projects' bookmark list
/// ie: the URL is in the format artcode://<project uuid>/remotes
- (BOOL)isArtCodeProjectRemotesList;

/// Gets the UUIDs encoded in the URL if present. The array is sorted with the project UUID at index 0.
/// ie: the URL is in the format artcode://<project uuid>[-<item uuid>]...
- (NSArray *)artCodeUUIDs;

////////////////////////////////////////////////////// TODO remove/refactor methods below this point

/// Indicate if the URL has a bookmarks specifier.
- (BOOL)isBookmarksVariant;
- (NSURL *)URLByAddingBookmarksVariant;

/// Remotes 
- (BOOL)isRemotesVariant;
- (NSURL *)URLByAddingRemotesVariant;

/// Indicates if the URL should be opened with a remote connection
- (BOOL)isRemoteURL;

/// Substitute / with ▸
- (NSString *)prettyPath;

/// Returns a string that has a pretty path format that removes '.weakpkg' extensions and adds ▸ instead of /
- (NSString *)prettyPathRelativeToProjectDirectory;

@end

@interface NSString (ArtCodeURL)

/// Substitute / with ▸
- (NSString *)prettyPath;

@end
