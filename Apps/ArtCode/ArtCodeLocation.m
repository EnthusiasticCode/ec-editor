//
//  ArtCodeLocation.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "ArtCodeRemote.h"
#import "NSString+Utilities.h"


@interface ArtCodeTab (ArtCodeLocation)

/// Pushes a location to the tab's history.
/// Changes the current location to the newly pushed location, and deletes any history items following the previously current one
- (void)pushLocation:(ArtCodeLocation *)location;

/// Updates the current location with the given one.
/// This method can be used to change some properties of the current location 
/// without leaving traces in the history.
- (void)updateCurrentLocationWithLocation:(ArtCodeLocation *)location;

@end

#pragma mark -

@interface ArtCodeTab (ArtCodeLocation_Internal)

/// Pushes the location built with the given parameters
- (void)pushLocationWithType:(ArtCodeLocationType)type project:(ArtCodeProject *)project data:(NSData *)data;

@end

#pragma mark -

@implementation ArtCodeLocation

- (ArtCodeLocationType)type {
  return self.typeInt16Value;
}

- (void)setType:(ArtCodeLocationType)type {
  self.typeInt16Value = type;
}

+ (NSSet *)keyPathsForValuesAffectingType {
  return [NSSet setWithObjects:@"typeInt16Value", nil];
}

#pragma mark - Utitlity methods

- (BOOL)isProjectsList {
  return self.type == ArtCodeLocationTypeProjectsList;
}

- (BOOL)isProjectBookmarksList {
  return self.type == ArtCodeLocationTypeBookmarksList;
}

- (BOOL)isProjectRemotesList {
  return self.type == ArtCodeLocationTypeRemotesList;
}

- (BOOL)isDirectory {
  return self.type == ArtCodeLocationTypeDirectory;
}

- (BOOL)isProject {
  return self.type == ArtCodeLocationTypeProject;
}

- (BOOL)isTextFile {
  return self.type == ArtCodeLocationTypeTextFile;
}

- (BOOL)isRemoteDirectory {
  return self.type == ArtCodeLocationTypeRemoteDirectory;
}

- (BOOL)isDocSet {
  return self.type == ArtCodeLocationTypeDocSet;
}

#pragma mark Data Properties

- (NSURL *)url {
  switch (self.type) {
    case ArtCodeLocationTypeProject:
      return self.project.fileURL;
      
    case ArtCodeLocationTypeDirectory:
    case ArtCodeLocationTypeTextFile:
    case ArtCodeLocationTypeDocSet:
    {
      // If a file, data is a bookmark data URL
      BOOL isStale = NO;
      NSURL *url = [NSURL URLByResolvingBookmarkData:self.data options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&isStale error:NULL];
      // TODO do something if it's stale
      return url;
    }
      
    case ArtCodeLocationTypeRemoteDirectory:
    {
      // If a remote directory location, data is a string containing the remote path
      return [self.remote.url URLByAppendingPathComponent:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
    }
      
    default:
      return nil;
  }
}

- (NSString *)name {
  return self.url.lastPathComponent;
}

- (NSString *)fileExtension {
  return self.url.pathExtension;
}

- (NSString *)path {
  NSString *path = self.url.path;
  switch (self.type) {
    case ArtCodeLocationTypeDocSet:
    {
      path = [path substringFromIndex:NSMaxRange([path rangeOfString:@"Contents/Resources/Documents"])];
    }
      
    case ArtCodeLocationTypeDirectory:
    case ArtCodeLocationTypeTextFile:
    {
      path = [path substringFromIndex:self.project.fileURL.path.length];
    }
      
    default:
      break;
  }
  return path;
}

- (NSString *)prettyPath {
  return self.path.prettyPath;
}

@end

#pragma mark -

@implementation ArtCodeTab (Location)

- (void)pushDefaultProjectSet {
  [self pushLocationWithType:ArtCodeLocationTypeProjectsList project:nil data:nil];
}

- (void)pushProject:(ArtCodeProject *)project {
  [self pushLocationWithType:ArtCodeLocationTypeProject project:project data:nil];
}

@end

#pragma mark -

@implementation ArtCodeTab (ArtCodeLocation_Internal)

- (void)pushLocationWithType:(ArtCodeLocationType)type project:(ArtCodeProject *)project data:(NSData *)data {
  ArtCodeLocation *location = [ArtCodeLocation insertInManagedObjectContext:self.managedObjectContext];
  if (type) {
    location.type = type;
  }
  if (project) {
    location.project = project;
  }
  if (data) {
    location.data = data;
  }
  location.tab = self;
  [self pushLocation:location];
}

@end