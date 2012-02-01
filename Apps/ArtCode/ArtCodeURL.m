//
//  ArtCodeURL.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeURL.h"
#import "ArtCodeProject.h"
#import "NSURL+Utilities.h"

static NSString * const ProjectsDirectoryName = @"LocalProjects";

@interface ArtCodeURL ()
+ (NSUInteger)_projectsDirectoryPathComponentsCount;
@end

@implementation ArtCodeURL

+ (NSURL *)projectsDirectory
{
    static NSURL *_projectsDirecotry = nil;
    if (!_projectsDirecotry)
        _projectsDirecotry = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ProjectsDirectoryName isDirectory:YES];
    return _projectsDirecotry;
}

+ (NSString *)pathRelativeToProjectsDirectory:(NSURL *)fileURL
{
    if (![fileURL isFileURL])
        return nil;
    NSArray *pathComponents = [[fileURL URLByStandardizingPath] pathComponents];
    if (![[pathComponents subarrayWithRange:NSMakeRange(0, self._projectsDirectoryPathComponentsCount)] isEqualToArray:[[self projectsDirectory] pathComponents]])
        return nil;
    pathComponents = [pathComponents subarrayWithRange:NSMakeRange(self._projectsDirectoryPathComponentsCount, [pathComponents count] - self._projectsDirectoryPathComponentsCount)];
    return [NSString pathWithComponents:pathComponents];
}

+ (NSString *)projectNameFromURL:(NSURL *)url isProjectRoot:(BOOL *)isProjectRoot
{
    NSString *path = [self pathRelativeToProjectsDirectory:url];
    if (!path)
        return nil;
    NSArray *components = [path pathComponents];
    if (isProjectRoot)
        *isProjectRoot = ([components count] == 1);
    return [components count] >= 1 ? [[components objectAtIndex:0] stringByDeletingPathExtension] : nil;
}

#pragma mark - Private methods

+ (NSUInteger)_projectsDirectoryPathComponentsCount
{
    static NSUInteger __projectsDirectoryPathComponentsCount = 0;
    if (!__projectsDirectoryPathComponentsCount)
    {
        __projectsDirectoryPathComponentsCount = [[[self projectsDirectory] pathComponents] count];
    }
    return __projectsDirectoryPathComponentsCount;
}

@end

@implementation NSURL (ArtCodeURL)

- (ArtCodeProject *)project
{
    // TODO cache this value?
    NSString *projectName = [ArtCodeURL projectNameFromURL:self isProjectRoot:NULL];
    if ([ArtCodeProject projectWithNameExists:projectName])
        return [ArtCodeProject projectWithName:projectName];
    return nil;
}

- (BOOL)isBookmarksVariant
{
    return [[self fragmentDictionary] objectForKey:@"bookmarks"] != nil;
}

- (NSURL *)URLByAddingBookmarksVariant
{
    NSMutableDictionary *fragments = [[self fragmentDictionary] mutableCopy];
    if ([fragments objectForKey:@"bookmarks"] != nil)
        return [self copy];
    if (fragments == nil)
        fragments = [NSMutableDictionary new];
    [fragments setObject:@"" forKey:@"bookmarks"];
    return [self URLByAppendingFragmentDictionary:fragments];
}

- (NSString *)prettyPathRelativeToProjectDirectory
{
    return [[[ArtCodeURL pathRelativeToProjectsDirectory:self] stringByReplacingOccurrencesOfString:@".weakpkg" withString:@""] stringByReplacingOccurrencesOfString:@"/" withString:@" ▸ "];
}

@end
