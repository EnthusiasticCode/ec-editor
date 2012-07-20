//
//  ArtCodeLocation.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"

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

@end
