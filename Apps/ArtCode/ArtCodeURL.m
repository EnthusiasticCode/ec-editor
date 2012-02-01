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
    NSString *projectsPath = [[self projectsDirectory] path];
    NSString *path = [url path];
    if (![path hasPrefix:projectsPath])
        return nil;
    path = [path substringFromIndex:[projectsPath length]];
    NSArray *components = [path pathComponents];
    if (isProjectRoot)
        *isProjectRoot = ([components count] == 2);
    return [components count] >= 2 ? [[components objectAtIndex:1] stringByDeletingPathExtension] : nil;
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
    NSString *projectName = [ArtCodeURL projectNameFromURL:self isProjectRoot:NULL];
    if ([ArtCodeProject projectWithNameExists:projectName])
        return [ArtCodeProject projectWithName:projectName];
    return nil;
}

- (NSString *)prettyPathRelativeToProjectDirectory
{
    return [[[ArtCodeURL pathRelativeToProjectsDirectory:self] stringByReplacingOccurrencesOfString:@".weakpkg" withString:@""] stringByReplacingOccurrencesOfString:@"/" withString:@" ▸ "];
}

@end
