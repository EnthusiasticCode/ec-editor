//
//  ArtCodeLocation.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeLocation.h"

#import "ACProject.h"


static NSString * const ProjectsDirectoryName = @"LocalProjects";
static NSString * const ArtCodeLocationScheme = @"artcode";


@implementation ArtCodeLocation

+ (NSURL *)ArtCodeLocationWithProject:(ACProject *)project type:(ArtCodeLocationType)type path:(NSString *)path {
  ASSERT(NO);
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
