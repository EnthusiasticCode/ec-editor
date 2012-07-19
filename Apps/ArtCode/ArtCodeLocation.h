//
//  ArtCodeLocation.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "ArtCodeProjectSet.h"
#import "ArtCodeRemote.h"

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

@interface ArtCodeLocation : _ArtCodeLocation

/// Indicates the type of the location. See ArtCodeLocationType enum for more informations.
@property (nonatomic) ArtCodeLocationType type;

#pragma mark Top level locations

/// Indicates if the location points to the default projects list
- (BOOL)isProjectsList;

/// Indicates if the location points to a project's bookmark list
- (BOOL)isProjectBookmarksList;

/// Indicates if the URL points to a project's bookmark list
- (BOOL)isProjectRemotesList;

#pragma mark URL specific

/// Indicate if the URL is a directory.
- (BOOL)isDirectory;
- (BOOL)isProject;
- (BOOL)isFile;
- (BOOL)isTextFile;
- (BOOL)isRemote;
- (BOOL)isFileBookmark;
- (BOOL)isDocset;

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

@interface NSURL (ArtCodeLocation)

/// Returns the location of the url if it can be inferred, or nil.
- (ArtCodeLocation *)location;

@end

@interface ArtCodeProject (ArtCodeLocation)

/// Returns the location of the project
- (ArtCodeLocation *)location;

/// Returns the location of the project's bookmarks list
- (ArtCodeLocation *)bookmarksListLocation;

/// Returns the location of the project's remotes list
- (ArtCodeLocation *)remotesListLocation;

@end

@interface ArtCodeProjectSet (ArtCodeLocation)

/// Returns the location of the project set
- (ArtCodeLocation *)location;

@end

@interface ArtCodeRemote (ArtCodeLocation)

/// Returns a location for the remote with the given path
- (ArtCodeLocation *)locationWithPath:(NSString *)path;

@end