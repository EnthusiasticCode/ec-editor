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

@end

@interface NSURL (ArtCodeURL)

/// Get a mask indicating properties of the URL. See ArtCodeURLType enum for more informations.
- (NSUInteger)artCodeURLTypeMask;

#pragma mark Top level URLs

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

#pragma mark URL specific

/// Indicate if the URL is a directory.
- (BOOL)isArtCodeDirectory;
- (BOOL)isArtCodeProjectDirectory;
- (BOOL)isArtCodeFile;
- (BOOL)isArtCodeTextFile;
- (BOOL)isArtCodeRemote;
- (BOOL)isArtCodeFileBookmark;

/// Returns a file:// URL from either an artcode or a file URL.
- (NSURL *)artCodeFileURL;

#pragma mark Utilities

/// Substitute / with ▸
- (NSString *)prettyPath; // TODO rename to artCodePrettyPath.

@end

@interface NSString (ArtCodeURL)

/// Substitute / with ▸
- (NSString *)prettyPath;

@end
