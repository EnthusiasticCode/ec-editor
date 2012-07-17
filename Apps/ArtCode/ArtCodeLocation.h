//
//  ArtCodeLocation.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Location.h"

@class ArtCodeProject;

typedef enum {
  ArtCodeLocationTypeProjectsList,
  ArtCodeLocationTypeProject,
  ArtCodeLocationTypeDirectory,
  ArtCodeLocationTypeTextFile,
  ArtCodeLocationTypeBookmarksList,
  ArtCodeLocationTypeRemotesList,
  ArtCodeLocationTypeRemoteDirectory,
  ArtCodeLocationTypeDocset,
} ArtCodeLocationType;

@interface ArtCodeLocation : Location

/// Create a new ArtCodeLocation encoding the project, type and path.
+ (ArtCodeLocation *)locationWithType:(ArtCodeLocationType)type projectName:(NSString *)projectName url:(NSURL *)url;

- (NSString *)stringRepresentation;

- (id)initWithStringRepresentation:(NSString *)string;

/// Get a mask indicating properties of the URL. See ArtCodeLocationType enum for more informations.
- (ArtCodeLocationType)artCodeType;

#pragma mark Top level URLs

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
- (BOOL)isArtCodeProject;
- (BOOL)isArtCodeFile;
- (BOOL)isArtCodeTextFile;
- (BOOL)isArtCodeRemote;
- (BOOL)isArtCodeFileBookmark;
- (BOOL)isArtCodeDocset;

/// Returns a file:// URL from either an artcode or a file URL.
- (NSURL *)url;

/// Returns the name of the ArtCodeRemote URL
- (NSString *)artCodeRemoteName;

- (NSString *)name;

- (NSString *)prettyName;

- (NSString *)fileExtension;

- (NSString *)projectName;

/// The path from the project containing the file name.
- (NSString *)path;

- (NSString *)prettyPath;


- (ArtCodeLocation *)locationByAppendingPathComponent:(NSString *)pathComponent;

@end

