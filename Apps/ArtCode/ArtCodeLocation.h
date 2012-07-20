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
  ArtCodeLocationTypeDocSet,
} ArtCodeLocationType;

/// Being a CoreData object, a location should be created using the methods in it's parent ArtCodeTab.
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
- (BOOL)isTextFile;
- (BOOL)isRemoteDirectory;
- (BOOL)isDocSet;

/// Returns a file:// URL from either an artcode or a file URL.
- (NSURL *)url;

/// Returns a useful name for the location. Usually the file name if present.
- (NSString *)name;

- (NSString *)fileExtension;

/// The path from the project containing the file name.
- (NSString *)path;

- (NSString *)prettyPath;

@end
