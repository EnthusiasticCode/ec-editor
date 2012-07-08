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

NSString * const artCodeURLProjectListPath = @"projects";
NSString * const artCodeURLProjectBookmarkListPath = @"/bookmarks";
NSString * const artCodeURLProjectRemoteListPath = @"/remotes";


@implementation ArtCodeURL

+ (NSURL *)artCodeURLWithProject:(ACProject *)project item:(ACProjectItem *)item path:(NSString *)path
{
  NSString *URLString = nil;
  if (path && ![path hasPrefix:@"/"])
    path = [@"/" stringByAppendingString:path];
  if (item)
  {
    ASSERT(project);
    ASSERT(item.project == project);
    URLString = [NSString stringWithFormat:@"%@://%@-%@%@", artCodeURLScheme, [project UUID], [item UUID], path ? path : @""];
  }
  else if (project)
  {
    URLString = [NSString stringWithFormat:@"%@://%@%@", artCodeURLScheme, [project UUID], path ? path : @""];
  }
  else if (path)
  {
    URLString = [NSString stringWithFormat:@"%@:/%@", artCodeURLScheme, path];
  }
  else 
  {
    return nil;
  }
  return [NSURL URLWithString:URLString];
}

@end

#pragma mark -

@implementation NSURL (ArtCodeURL)

- (BOOL)isArtCodeURL
{
  return [self.scheme isEqualToString:artCodeURLScheme];
}

- (BOOL)isArtCodeProjectsList
{
  return [self.host isEqualToString:artCodeURLProjectListPath];
}

- (BOOL)isArtCodeProjectBookmarksList
{
  return [self.host length] == 36 && [self.path isEqualToString:artCodeURLProjectBookmarkListPath];
}

- (BOOL)isArtCodeProjectRemotesList
{
  return [self.host length] == 36 && [self.path isEqualToString:artCodeURLProjectRemoteListPath];
}

- (NSString *)prettyPath
{
  return [[self path] prettyPath];
}

@end

#pragma mark -

@implementation NSString (ArtCodeURL)

- (NSString *)prettyPath
{
  return [self stringByReplacingOccurrencesOfString:@"/" withString:@" ▸ "];
}

@end
