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
  ArtCodeLocationTypeUnknown = 0,
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

/// Returns a location with the given type. Only valid for location types that don't require other parameters
+ (ArtCodeLocation *)locationWithType:(ArtCodeLocationType)type;

/// Returns a ArtCodeLocationTypeProject location with the given project
+ (ArtCodeLocation *)locationWithProject:(ArtCodeProject *)project;

/// Returns a location encoding the project, type and path.
+ (ArtCodeLocation *)locationWithType:(ArtCodeLocationType)type projectName:(NSString *)projectName url:(NSURL *)url;

/// Returns a location by inferring the type (directory or textfile) for the given project and file url.
+ (ArtCodeLocation *)locationWithAutoTypeForProjectName:(NSString *)projectName fileURL:(NSURL *)fileURL;

/// Get a mask indicating properties of the URL. See ArtCodeLocationType enum for more informations.
- (ArtCodeLocationType)type;

#pragma mark Top level locations

/// Indicates if the location points to the default projects list
- (BOOL)isArtCodeProjectsList;

/// Indicates if the location points to a project's bookmark list
- (BOOL)isArtCodeProjectBookmarksList;

/// Indicates if the URL points to a project's bookmark list
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

