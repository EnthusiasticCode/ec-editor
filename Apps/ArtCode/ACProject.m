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


@interface ACProjectBookmark (/* Private methods */)

@property (nonatomic, weak) ACProject *project;

- (id)initWithProject:(ACProject *)project URL:(NSURL *)url note:(NSString *)note;
- (id)initWithProject:(ACProject *)project propertyDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)propertyDictionary;

@end


@implementation ACProject {
    BOOL _dirty;
    NSURL *_plistUrl;
    
    NSMutableArray *bookmarks;
}

#pragma mark Properties

@synthesize URL, labelColor, bookmarks;

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

- (void)setLabelColor:(UIColor *)value
{
    if (value == labelColor)
        return;
    
    _dirty = YES;
    [self willChangeValueForKey:@"labelColor"];
    labelColor = value;
    [self didChangeValueForKey:@"labelColor"];
    // TODO remove this when a global autosaving method is created
    [self flush];
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
    __block NSDictionary *plist = nil;
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:_plistUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
        if ([[NSFileManager new] fileExistsAtPath:[newURL path]])
            plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:newURL] options:NSPropertyListImmutable format:NULL error:NULL];
    }];
    if (plist)
    {
        labelColor = [UIColor colorWithHexString:[plist objectForKey:@"labelColor"]];
        NSArray *plistBookmarks = [plist objectForKey:@"bookmarks"];
        if ([plistBookmarks count])
        {
            bookmarks = [NSMutableArray new];
            for (NSDictionary *b in plistBookmarks)
            {
                [bookmarks addObject:[[ACProjectBookmark alloc] initWithProject:self propertyDictionary:b]];
            }
        }
    }
    
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
    if (!_dirty)
        return;
    
    NSMutableDictionary *plist = [NSMutableDictionary new];
    if (labelColor)
        [plist setObject:[labelColor hexString] forKey:@"labelColor"];
    if ([bookmarks count])
    {
        NSMutableArray *plistBookmarks = [[NSMutableArray alloc] initWithCapacity:[bookmarks count]];
        for (ACProjectBookmark *b in bookmarks)
        {
            [plistBookmarks addObject:[b propertyDictionary]];
        }
        [plist setObject:plistBookmarks forKey:@"bookmarks"];
    }
    
    [[[ECFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:_plistUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
        [[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL] writeToURL:newURL atomically:YES];
    }];
    
    _dirty = NO;
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

#pragma mark Bookmakrs methods

- (void)addBookmarkWithFileURL:(NSURL *)fileURL line:(NSUInteger)line note:(NSString *)note
{
    if (!bookmarks)
        bookmarks = [NSMutableArray new];
    
    ACProjectBookmark *bookmark = [[ACProjectBookmark alloc] initWithProject:self URL:[fileURL URLByAppendingFragmentDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:line] forKey:@"line"]] note:note];
    [bookmarks addObject:bookmark];
    _dirty = YES;
    
    // TODO remove flush here
    [self flush];
}

- (void)removeBookmark:(ACProjectBookmark *)bookmark
{
    [bookmarks removeObject:bookmark];
}

- (NSArray *)bookmarksForFile:(NSURL *)fileURL atLine:(NSUInteger)lineNumber
{
    NSString *filePath = [fileURL absoluteString];
    NSString *projectPath = [self.URL absoluteString];
    if (![filePath hasPrefix:projectPath])
        return nil;
    filePath = [filePath substringFromIndex:[projectPath length]];
    
    NSMutableArray *result = [NSMutableArray new];
    for (ACProjectBookmark *bookmark in bookmarks)
    {
        if (![bookmark.bookmarkPath hasPrefix:filePath])
            continue;
        if ([bookmark line] == lineNumber)
            [result addObject:bookmark];
    }
    return result;
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


@implementation ACProjectBookmark

@synthesize bookmarkPath, project, note;

- (NSURL *)URL
{
    return [NSURL URLWithString:bookmarkPath relativeToURL:project.URL];
}

- (NSUInteger)line
{
    return [[[self.URL fragmentDictionary] objectForKey:@"line"] integerValue];
}

#pragma mark Private methods

- (id)initWithProject:(ACProject *)aProject URL:(NSURL *)aUrl note:(NSString *)aNote
{
    self = [super init];
    if (!self)
        return nil;
    
    ECASSERT(aProject != nil && aUrl != nil);
    
    project = aProject;
    bookmarkPath = [[aUrl absoluteString] substringFromIndex:[[aProject.URL absoluteString] length]];
    note = aNote;
    return self;
}

- (id)initWithProject:(ACProject *)aProject propertyDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self)
        return nil;
    
    project = aProject;
    bookmarkPath = [dictionary objectForKey:@"URL"];
    note = [dictionary objectForKey:@"note"];
    
    return self;
}

- (NSDictionary *)propertyDictionary
{
    if (note)
    {
        return [NSDictionary dictionaryWithObjectsAndKeys:bookmarkPath, @"URL", note, @"note", nil];
    }
    else
    {
        return [NSDictionary dictionaryWithObject:bookmarkPath forKey:@"URL"];
    }
}

@end
