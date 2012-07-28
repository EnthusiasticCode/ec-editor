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
#import "NSURL+Utilities.h"


#pragma mark -

@interface ArtCodeTab (ArtCodeLocation_Internal)

/// Pushes the location built with the given parameters
- (void)pushLocationWithType:(ArtCodeLocationType)type project:(ArtCodeProject *)project remote:(ArtCodeRemote *)remote data:(NSData *)data;

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
  [self pushLocationWithType:ArtCodeLocationTypeProjectsList project:nil remote:nil data:nil];
}

- (void)pushProject:(ArtCodeProject *)project {
  ASSERT(project);
  [self pushLocationWithType:ArtCodeLocationTypeProject project:project remote:nil data:nil];
}

- (void)pushDocSetURL:(NSURL *)url {
  ASSERT(url);
  [self pushLocationWithType:ArtCodeLocationTypeDocSet project:nil remote:nil data:[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)pushFileURL:(NSURL *)url withProject:(ArtCodeProject *)project {
  ASSERT(project && url);
  NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark | NSURLBookmarkCreationPreferFileIDResolution includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
  if ([url isDirectory]) {
    [self pushLocationWithType:ArtCodeLocationTypeDirectory project:project remote:nil data:bookmarkData];
  } else {
    [self pushLocationWithType:ArtCodeLocationTypeTextFile project:project remote:nil data:bookmarkData];
  }
}

- (void)pushFileURL:(NSURL *)url withProject:(ArtCodeProject *)project lineNumber:(NSUInteger)lineNumber {
  [self pushFileURL:url withProject:project];
}

- (void)pushBookmarksListForProject:(ArtCodeProject *)project {
  ASSERT(project);
  [self pushLocationWithType:ArtCodeLocationTypeBookmarksList project:project remote:nil data:nil];
}

- (void)pushRemotesListForProject:(ArtCodeProject *)project {
  ASSERT(project);
  [self pushLocationWithType:ArtCodeLocationTypeRemotesList project:project remote:nil data:nil];
}

- (void)pushRemotePath:(NSString *)path withRemote:(ArtCodeRemote *)remote {
  ASSERT(path && remote);
  [self pushLocationWithType:ArtCodeLocationTypeRemoteDirectory project:remote.project remote:remote data:[path dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

#pragma mark -

@implementation ArtCodeTab (ArtCodeLocation_Internal)

- (void)pushLocationWithType:(ArtCodeLocationType)type project:(ArtCodeProject *)project remote:(ArtCodeRemote *)remote data:(NSData *)data {
  ArtCodeLocation *location = [ArtCodeLocation insertInManagedObjectContext:self.managedObjectContext];
  if (type) {
    location.type = type;
  }
  if (project) {
    location.project = project;
  }
  if (remote) {
    location.remote = remote;
  }
  if (data) {
    location.data = data;
  }
  [self pushLocation:location];
}

@end