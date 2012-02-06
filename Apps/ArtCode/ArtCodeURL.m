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
#import <objc/runtime.h>

static NSString * const ProjectsDirectoryName = @"LocalProjects";

@interface ArtCodeURL ()

+ (NSUInteger)_standardizedProjectsDirectoryLength;

@end

@implementation ArtCodeURL

+ (NSURL *)projectsDirectory
{
    static NSURL *_projectsDirectory = nil;
    if (!_projectsDirectory)
        _projectsDirectory = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ProjectsDirectoryName isDirectory:YES];
    return _projectsDirectory;
}

+ (NSString *)pathRelativeToProjectsDirectory:(NSURL *)fileURL
{
    if (![fileURL isFileURL])
        return nil;
    NSString *filePath = [[fileURL URLByStandardizingPath] absoluteString];
    if ([filePath length] <= [self _standardizedProjectsDirectoryLength])
        return nil;
    return [[filePath substringFromIndex:[self _standardizedProjectsDirectoryLength]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
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

+ (NSUInteger)_standardizedProjectsDirectoryLength
{
    static NSUInteger __standardizedProjectsDirectoryLength = 0;
    if (__standardizedProjectsDirectoryLength == 0)
        __standardizedProjectsDirectoryLength = [[[[self projectsDirectory] URLByStandardizingPath] absoluteString] length];
    return __standardizedProjectsDirectoryLength;
}

@end

@implementation NSURL (ArtCodeURL)

- (ArtCodeProject *)project
{
    static const void *urlProjectKey;
    ArtCodeProject *project = objc_getAssociatedObject(self, &urlProjectKey);
    if (!project)
    {
        project = [ArtCodeProject projectWithURL:self];
        objc_setAssociatedObject(self, &urlProjectKey, project, OBJC_ASSOCIATION_ASSIGN);
    }
    ECASSERT(project && "Asked project from a non project URL");
    return project;
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
