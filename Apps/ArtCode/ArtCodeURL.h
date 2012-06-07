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

/// Returns the UUID of the project or item referenced by the URL or nil
- (id)artCodeProjectUUID;
- (id)artCodeItemUUID;

/// Substitute / with ▸
- (NSString *)prettyPath;

@end

@interface NSString (ArtCodeURL)

/// Substitute / with ▸
- (NSString *)prettyPath;

@end
