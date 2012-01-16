//
//  ACProject.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 14/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import <ECFoundation/ECFileCoordinator.h>
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECArchive/ECArchive.h>
#import <ECFoundation/ECCache.h>
#import "UIColor+HexColor.h"

static NSString * const ACProjectsDirectoryName = @"ACLocalProjects";
static NSString * const ACProjectPlistFileName = @".acproj";
static NSString * const ACProjectExtension = @".weakpkg";
static ECCache *openProjects = nil;

@interface ACProject ()

@property (nonatomic, strong, readonly) NSMutableDictionary *plist;

@end


@implementation ACProject {
    NSURL *_plistUrl;
}

#pragma mark Properties

@synthesize URL, plist;

- (NSString *)name
{
    return [[self.URL lastPathComponent] stringByDeletingPathExtension];
}

- (void)setName:(NSString *)name
{
    if (![name hasSuffix:ACProjectExtension])
        name = [name stringByAppendingString:ACProjectExtension];
    
    if ([name isEqualToString:[self.URL lastPathComponent]])
        return;
    ECASSERT(![[self class] projectWithNameExists:name]);
    [self willChangeValueForKey:@"name"];
    NSURL *newURL = [[self.URL URLByDeletingLastPathComponent] URLByAppendingPathComponent:name];
    ECFileCoordinator *coordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateWritingItemAtURL:self.URL options:NSFileCoordinatorWritingForMoving writingItemAtURL:newURL options:0 error:NULL byAccessor:^(NSURL *newURL1, NSURL *newURL2) {
        [[NSFileManager new] moveItemAtURL:newURL1 toURL:newURL2 error:NULL];
        [coordinator itemAtURL:newURL1 didMoveToURL:newURL2];
    }];
    [openProjects removeObjectForKey:URL];
    URL = newURL;
    [openProjects setObject:self forKey:URL];
    [self didChangeValueForKey:@"name"];
}

- (UIColor *)labelColor
{
    return [UIColor colorWithHexString:[self.plist objectForKey:@"labelColor"]];
}

- (void)setLabelColor:(UIColor *)labelColor
{
    [self willChangeValueForKey:@"labelColor"];
    [self.plist setObject:[labelColor hexString] forKey:@"labelColor"];
    [self didChangeValueForKey:@"labelColor"];
}

- (NSMutableDictionary *)plist
{
    if (!plist)
        plist = [NSMutableDictionary new];
    return plist;
}

#pragma mark Initializing and exporting projects

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self)
        return nil;
    
    ECASSERT([[NSFileManager new] fileExistsAtPath:[url path]]);
    
    URL = url;
    
    _plistUrl = [URL URLByAppendingPathComponent:ACProjectPlistFileName];
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:_plistUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
        if ([[NSFileManager new] fileExistsAtPath:[newURL path]])
            plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:newURL] options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
    }];
    
    return self;
}

- (id)initByDecompressingFileAtURL:(NSURL *)compressedFileUrl toURL:(NSURL *)url
{
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:compressedFileUrl options:0 writingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        [[NSFileManager new] createDirectoryAtURL:newWritingURL withIntermediateDirectories:YES attributes:nil error:NULL];
        [ECArchive extractArchiveAtURL:newReadingURL toDirectory:newWritingURL];
    }];
    
    self = [self initWithURL:url];
    if (!self)
        return nil;
    return self;
}

- (void)flush
{
    if ([plist count] == 0)
        return;
    
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:_plistUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
        [[NSPropertyListSerialization dataWithPropertyList:self.plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL] writeToURL:newURL atomically:YES];
    }];
}

- (BOOL)compressProjectToURL:(NSURL *)exportUrl
{
    [self flush];
    
    __block BOOL result = NO;
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:self.URL options:0 writingItemAtURL:exportUrl options:NSFileCoordinatorWritingForReplacing error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        result = [ECArchive compressDirectoryAtURL:newReadingURL toArchive:newWritingURL];
    }];
    return result;
}

- (void)dealloc
{
    [self flush];
}

#pragma mark Class methods

+ (NSURL *)projectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACProjectsDirectoryName isDirectory:YES];
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

+ (BOOL)projectWithNameExists:(NSString *)name
{
    if (![name hasSuffix:ACProjectExtension])
        name = [name stringByAppendingString:ACProjectExtension];
    
    BOOL isDirectory = NO;
    BOOL exists =[[NSFileManager new] fileExistsAtPath:[[[self projectsDirectory] URLByAppendingPathComponent:name isDirectory:YES] path] isDirectory:&isDirectory];
    return exists && isDirectory;
}

+ (NSString *)validNameForNewProjectName:(NSString *)name
{
    name = [name stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    
    NSFileManager *new = [NSFileManager new];
    NSString *projectsPath = [[self projectsDirectory] path];
    
    NSUInteger count = 0;
    NSString *result = name;
    while ([new fileExistsAtPath:[projectsPath stringByAppendingPathComponent:[result stringByAppendingString:ACProjectExtension]]])
    {
        result = [name stringByAppendingFormat:@" (%u)", ++count];
    }
    return result;
}

+ (NSURL *)projectURLFromName:(NSString *)name
{
    if (![name hasSuffix:ACProjectExtension])
        name = [name stringByAppendingString:ACProjectExtension];
    
    return [[self projectsDirectory] URLByAppendingPathComponent:name];
}

+ (id)projectWithName:(NSString *)name
{
    name = [name stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    if (![name hasSuffix:ACProjectExtension])
        name = [name stringByAppendingString:ACProjectExtension];
    
    NSURL *projectUrl = [[self projectsDirectory] URLByAppendingPathComponent:name isDirectory:YES];
    
    if (!openProjects)
        openProjects = [ECCache new];
    
    id project = [openProjects objectForKey:projectUrl];
    if (project)
        return project;
    
    // Create project direcotry
    if (![[NSFileManager new] fileExistsAtPath:[projectUrl path]])
    {
        [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:projectUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
            [[NSFileManager new] createDirectoryAtURL:projectUrl withIntermediateDirectories:NO attributes:nil error:NULL];
        }];
    }
    
    // Open project
    project = [[self alloc] initWithURL:projectUrl];
    [openProjects setObject:project forKey:projectUrl];
    return project;
}

+ (id)projectWithURL:(NSURL *)url
{
    ECASSERT(url != nil);
    
    NSString *projectName = [self projectNameFromURL:url isProjectRoot:NULL];
    if (!projectName)
        return nil;
    
    return [self projectWithName:projectName];
}

@end
