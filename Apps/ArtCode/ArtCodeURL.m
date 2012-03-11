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

#import "ACProject.h"
#import "ACProjectItem.h"


static NSString * const ProjectsDirectoryName = @"LocalProjects";
static NSString * const artCodeURLScheme = @"artcode";

NSString * const artCodeURLProjectListPath = @"projects";
NSString * const artCodeURLProjectBookmarkListPath = @"bookmarks";
NSString * const artCodeURLProjectRemoteListPath = @"remotes";


@interface ArtCodeURL ()

+ (NSUInteger)_standardizedProjectsDirectoryLength;

@end

@implementation ArtCodeURL

+ (NSURL *)artCodeURLWithProject:(ACProject *)project item:(ACProjectItem *)item path:(NSString *)path
{
    NSString *URLString = nil;
    if (item)
    {
        ECASSERT(project);
        ECASSERT(item.project == project);
        URLString = [NSString stringWithFormat:@"%@://%@-%@/%@", artCodeURLScheme, [project UUID], [item UUID], path];
    }
    else if (project)
    {
        URLString = [NSString stringWithFormat:@"%@://%@/%@", artCodeURLScheme, [project UUID], path];
    }
    else if (path)
    {
        URLString = [NSString stringWithFormat:@"%@://%@", artCodeURLScheme, path];
    }
    else 
    {
        return nil;
    }
    return [NSURL URLWithString:URLString];
}

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

#pragma mark -

@implementation NSURL (ArtCodeURL)

- (BOOL)isArtCodeURL
{
    return [self.scheme isEqualToString:artCodeURLScheme];
}

- (BOOL)isArtCodeProjectsList
{
    return [self.path isEqualToString:artCodeURLProjectListPath];
}

- (BOOL)isArtCodeProjectBookmarksList
{
    return [self.path isEqualToString:artCodeURLProjectBookmarkListPath];
}

- (BOOL)isArtCodeProjectRemotesList
{
    return [self.path isEqualToString:artCodeURLProjectRemoteListPath];
}

- (NSArray *)artCodeUUIDs
{
    static NSRegularExpression *uuidRegExp = nil;
    if (!uuidRegExp)
        uuidRegExp = [NSRegularExpression regularExpressionWithPattern:@"(?:([\\da-f]{8}-[\\da-f]{4}-[\\da-f]{4}-[\\da-f]{4}-[\\da-f]{12})-?)+" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray *matches = [uuidRegExp matchesInString:self.host options:0 range:NSMakeRange(0, [self.host length])];
    if ([matches count] == 0)
        return nil;
    ECASSERT([matches count] == 1);
    NSTextCheckingResult *regExpResult = [matches objectAtIndex:0];
    NSInteger regExpResultCount = [regExpResult numberOfRanges];
    ECASSERT(regExpResultCount > 1);
    NSMutableArray *uuids = [NSMutableArray arrayWithCapacity:regExpResultCount - 1];
    for (NSInteger i = 1; i < regExpResultCount; ++i)
    {
        [uuids addObject:[self.host substringWithRange:[regExpResult rangeAtIndex:i]]];
    }
    return [uuids copy];
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

- (BOOL)isRemotesVariant
{
    return [[self fragmentDictionary] objectForKey:@"remotes"] != nil;
}

- (NSURL *)URLByAddingRemotesVariant
{
    NSMutableDictionary *fragments = [[self fragmentDictionary] mutableCopy];
    if ([fragments objectForKey:@"remotes"] != nil)
        return [self copy];
    if (fragments == nil)
        fragments = [NSMutableDictionary new];
    [fragments setObject:@"" forKey:@"remotes"];
    return [self URLByAppendingFragmentDictionary:fragments];
}

- (BOOL)isRemoteURL
{
    return [self.scheme isEqualToString:@"ftp"]
    || [self.scheme isEqualToString:@"ssh"]
    || [self.scheme isEqualToString:@"sftp"]
    || [self.scheme isEqualToString:@"http"]
    || [self.scheme isEqualToString:@"https"];
}

- (NSString *)prettyPath
{
    return [[self path] prettyPath];
}

- (NSString *)prettyPathRelativeToProjectDirectory
{
    return [[[ArtCodeURL pathRelativeToProjectsDirectory:self] stringByReplacingOccurrencesOfString:@".weakpkg" withString:@""] prettyPath];
}

@end

#pragma mark -

@implementation NSString (ArtCodeURL)

- (NSString *)prettyPath
{
    return [self stringByReplacingOccurrencesOfString:@"/" withString:@" ▸ "];
}

@end
