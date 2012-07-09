//
//  ArtCodeURL.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACProject;

typedef enum {
  ArtCodeURLTypeProjectsList,
  ArtCodeURLTypeProject,
  ArtCodeURLTypeDirectory,
  ArtCodeURLTypeFile,
  ArtCodeURLTypeTextFile,
  ArtCodeURLTypeBookmarksList,
  ArtCodeURLTypeBookmark,
  ArtCodeURLTypeRemotesList,
  ArtCodeURLTypeRemote,
} ArtCodeURLType;

@interface ArtCodeURL

/// Create a new NSURL encoding the project, type and path.
+ (NSURL *)artCodeURLWithProject:(ACProject *)project type:(ArtCodeURLType)type path:(NSString *)path;

@end

@interface NSURL (ArtCodeURL)

/// Get a mask indicating properties of the URL. See ArtCodeURLType enum for more informations.
- (ArtCodeURLType)artCodeType;

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
- (NSURL *)artCodeURLToActualURL;

/// Returns the name of the ArtCodeRemote URL
- (NSString *)artCodeRemoteName;

#pragma mark Utilities

/// Substitute / with ▸
- (NSString *)prettyPath; // TODO rename to artCodePrettyPath.

@end

@interface NSString (ArtCodeURL)

/// Substitute / with ▸
- (NSString *)prettyPath;

@end
