//
//  ArtCodeLocation.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeLocation.h"
#import "ArtCodeTab.h"

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

/// Returns a file:// URL from either an artcode or a file URL.
- (NSURL *)url;

/// Returns a useful name for the location. Usually the file name if present.
- (NSString *)name;

- (NSString *)fileExtension;

/// The path from the project containing the file name.
- (NSString *)path;

- (NSString *)prettyPath;

@end

@interface ArtCodeTab (Location)

- (void)pushDefaultProjectSet;

- (void)pushProject:(ArtCodeProject *)project;

- (void)pushDocSetURL:(NSURL *)url;

- (void)pushFileURL:(NSURL *)url withProject:(ArtCodeProject *)project;

- (void)pushFileURL:(NSURL *)url withProject:(ArtCodeProject *)project lineNumber:(NSUInteger)lineNumber;

- (void)pushBookmarksListForProject:(ArtCodeProject *)project;

- (void)pushRemotesListForProject:(ArtCodeProject *)project;

- (void)pushRemotePath:(NSString *)path withRemote:(ArtCodeRemote *)remote;

- (void)pushCopyOfLocation:(ArtCodeLocation *)location;

@end
