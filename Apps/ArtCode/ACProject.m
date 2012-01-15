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

static NSString * const ACProjectsDirectoryName = @"ACLocalProjects";
static NSString * const ACProjectPlistFileName = @"acproj.plist";


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
    return [self.URL lastPathComponent];
}

- (void)setName:(NSString *)name
{
    if ([name isEqualToString:[self.URL lastPathComponent]])
        return;
    ECASSERT(![[self class] projectWithNameExists:name]);
    [self willChangeValueForKey:@"name"];
    NSURL *newURL = [[self.URL URLByDeletingLastPathComponent] URLByAppendingPathComponent:name];
    ECFileCoordinator *coordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateWritingItemAtURL:self.URL options:NSFileCoordinatorWritingForMoving writingItemAtURL:newURL options:0 error:NULL byAccessor:^(NSURL *newURL1, NSURL *newURL2) {
        [[NSFileManager defaultManager] moveItemAtURL:newURL1 toURL:newURL2 error:NULL];
        [coordinator itemAtURL:newURL1 didMoveToURL:newURL2];
    }];
    URL = newURL;
    [self didChangeValueForKey:@"name"];
}

- (UIColor *)labelColor
{
    return [self.plist objectForKey:@"labelColor"];
}

- (void)setLabelColor:(UIColor *)labelColor
{
    [self willChangeValueForKey:@"labelColor"];
    [self.plist setObject:labelColor forKey:@"labelColor"];
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
    
    ECASSERT([[NSFileManager defaultManager] fileExistsAtPath:[url path]]);
    
    URL = url;
    
    _plistUrl = [URL URLByAppendingPathComponent:ACProjectPlistFileName];
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:_plistUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
        plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:newURL] options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
    }];
    
    return self;
}

- (id)initByDecompressingFileAtURL:(NSURL *)compressedFileUrl toURL:(NSURL *)url
{
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:compressedFileUrl options:0 writingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        [[NSFileManager defaultManager] createDirectoryAtURL:newWritingURL withIntermediateDirectories:YES attributes:nil error:NULL];
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
    
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:self.URL options:0 writingItemAtURL:exportUrl options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        [ECArchive compressDirectoryAtURL:newReadingURL toArchive:newWritingURL];
    }];
}

#pragma mark Class methods

+ (NSURL *)projectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACProjectsDirectoryName isDirectory:YES];
}

+ (BOOL)projectWithNameExists:(NSString *)name
{
    BOOL isDirectory = NO;
    BOOL exists =[[NSFileManager defaultManager] fileExistsAtPath:[[[self projectsDirectory] URLByAppendingPathComponent:name isDirectory:YES] path] isDirectory:&isDirectory];
    return exists && isDirectory;
}

+ (NSString *)validNameForProjectName:(NSString *)name
{
    name = [name stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSString *projectsPath = [[self projectsDirectory] path];
    
    NSUInteger count = 0;
    NSString *result = name;
    while ([defaultManager fileExistsAtPath:[projectsPath stringByAppendingPathComponent:result]])
    {
        result = [name stringByAppendingFormat:@" (%u)", ++count];
    }
    return result;
}

+ (id)projectWithName:(NSString *)name
{
    NSURL *projectUrl = [[self projectsDirectory] URLByAppendingPathComponent:[self validNameForProjectName:name] isDirectory:YES];
    
    // Create project direcotry
    if (![[NSFileManager defaultManager] fileExistsAtPath:[projectUrl path]])
    {
        [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:projectUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
            [[NSFileManager defaultManager] createDirectoryAtURL:projectUrl withIntermediateDirectories:NO attributes:nil error:NULL];
        }];
    }
    
    // Open project
    return [[self alloc] initWithURL:projectUrl];
}

@end
