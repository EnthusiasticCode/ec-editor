//
//  ArtCodeLocation.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "NSURL+Utilities.h"


static NSString * const ProjectsDirectoryName = @"LocalProjects";
static NSString * const ArtCodeLocationScheme = @"artcode";


@implementation ArtCodeLocation

+ (NSURL *)locationWithProject:(ArtCodeProject *)project type:(ArtCodeLocationType)type path:(NSString *)path {
  ASSERT(NO);
}

+ (ArtCodeLocation *)locationWithAutoTypeForProjectName:(NSString *)projectName fileURL:(NSURL *)fileURL {
  ArtCodeLocationType type = ArtCodeLocationTypeUnknown;
  if ([fileURL isDirectory]) {
    type = ArtCodeLocationTypeDirectory;
  } else {
    type = ArtCodeLocationTypeTextFile;
  }
  return [ArtCodeLocation locationWithType:type projectName:projectName url:fileURL];
}

- (BOOL)isArtCodeProjectsList {
  UNIMPLEMENTED();
}

- (BOOL)isArtCodeProjectBookmarksList {
  UNIMPLEMENTED();
}

- (BOOL)isArtCodeProjectRemotesList {
  UNIMPLEMENTED();
}


@end
