//
//  ArtCodeURL.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeURL.h"

#import "ACProject.h"


static NSString * const ProjectsDirectoryName = @"LocalProjects";
static NSString * const artCodeURLScheme = @"artcode";


@implementation ArtCodeURL

+ (NSURL *)artCodeURLWithProject:(ACProject *)project type:(ArtCodeURLType)type path:(NSString *)path {
  ASSERT(NO);
}

@end

#pragma mark -

@implementation NSURL (ArtCodeURL)

- (BOOL)isArtCodeURL {
  return [self.scheme isEqualToString:artCodeURLScheme];
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
