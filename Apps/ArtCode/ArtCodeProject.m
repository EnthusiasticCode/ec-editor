//
//  Project.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 14/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeProject.h"
#import "ArtCodeURL.h"
#import "NSURL+Utilities.h"
#import "ArchiveUtilities.h"
#import "WeakDictionary.h"
#import "UIColor+HexColor.h"
#import "Keychain.h"

static NSString * const ProjectPlistFileName = @".acproj";
static NSString * const ProjectExtension = @".weakpkg";
static WeakDictionary *openProjects = nil;


@interface ProjectBookmark (/* Private methods */)

@property (nonatomic, weak) ArtCodeProject *project;

- (id)initWithProject:(ArtCodeProject *)project URL:(NSURL *)url note:(NSString *)note;
- (id)initWithProject:(ArtCodeProject *)project propertyDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)propertyDictionary;

@end


@interface ProjectRemote ()

- (id)initWithPropertyDictionary:(NSDictionary *)dict;
- (NSDictionary *)propertyDictionary;

@end


@implementation ArtCodeProject {
    BOOL _dirty;
    NSURL *_plistUrl;
    
    NSMutableArray *bookmarks;
    NSMutableArray *remotes;
    
    /// Dictionary to map file paths to array of related bookamrks. This dictionary
    /// is used to quickly retrieve subsequent call from the same file without cycling 
    /// all bookmarks. It is reset for a certian file path when a bookmark is added or deleted.
    NSMutableDictionary *_fileToBookmarksCache;
}

#pragma mark Properties

@synthesize URL, labelColor, bookmarks, remotes;

- (NSString *)name
{
    return [[self.URL lastPathComponent] stringByDeletingPathExtension];
}

- (void)setName:(NSString *)name
{
    if (![name hasSuffix:ProjectExtension])
        name = [name stringByAppendingString:ProjectExtension];
    
    if ([name isEqualToString:[self.URL lastPathComponent]])
        return;
    ECASSERT(![[self class] projectWithNameExists:name]);
    NSURL *newURL = [[self.URL URLByDeletingLastPathComponent] URLByAppendingPathComponent:name];
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateWritingItemAtURL:self.URL options:NSFileCoordinatorWritingForMoving writingItemAtURL:newURL options:0 error:NULL byAccessor:^(NSURL *newURL1, NSURL *newURL2) {
        [[NSFileManager new] moveItemAtURL:newURL1 toURL:newURL2 error:NULL];
        [coordinator itemAtURL:newURL1 didMoveToURL:newURL2];
    }];
    [openProjects removeObjectForKey:URL];
    URL = newURL;
    [openProjects setObject:self forKey:URL];
}

- (void)setLabelColor:(UIColor *)value
{
    if (value == labelColor)
        return;
    
    _dirty = YES;
    labelColor = value;
}

#pragma mark Initializing and exporting projects

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self)
        return nil;
    
    ECASSERT([[NSFileManager new] fileExistsAtPath:[url path]]);
    
    URL = url;
    
    _plistUrl = [URL URLByAppendingPathComponent:ProjectPlistFileName];
    __block NSDictionary *plist = nil;
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:_plistUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
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
                [bookmarks addObject:[[ProjectBookmark alloc] initWithProject:self propertyDictionary:b]];
            }
        }
        NSArray *plistRemotes = [plist objectForKey:@"remotes"];
        if ([plistRemotes count])
        {
            remotes = [NSMutableArray new];
            for (NSDictionary *r in plistRemotes)
            {
                [remotes addObject:[[ProjectRemote alloc] initWithPropertyDictionary:r]];
            }
        }
    }
    
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
        NSMutableArray *plistBookmarks = [NSMutableArray arrayWithCapacity:[bookmarks count]];
        for (ProjectBookmark *b in bookmarks)
        {
            [plistBookmarks addObject:[b propertyDictionary]];
        }
        [plist setObject:plistBookmarks forKey:@"bookmarks"];
    }
    if ([remotes count])
    {
        NSMutableArray *plistRemotes = [NSMutableArray arrayWithCapacity:[remotes count]];
        for (ProjectRemote *remote in remotes)
        {
            [plistRemotes addObject:[remote propertyDictionary]];
        }
        [plist setObject:plistRemotes forKey:@"remotes"];
    }
    
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:_plistUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
        [[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL] writeToURL:newURL atomically:YES];
    }];
    
    _dirty = NO;
}

- (BOOL)compressProjectToURL:(NSURL *)exportUrl
{
    [self flush];
    
    __block BOOL result = NO;
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:self.URL options:0 writingItemAtURL:exportUrl options:NSFileCoordinatorWritingForReplacing error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        result = [ArchiveUtilities compressDirectoryAtURL:newReadingURL toArchive:newWritingURL];
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
    NSString *filePath = [fileURL absoluteString];
    NSString *projectPath = [self.URL absoluteString];
    if (![filePath hasPrefix:projectPath])
        return;
    
    if (!bookmarks)
        bookmarks = [NSMutableArray new];
    
    ProjectBookmark *bookmark = [[ProjectBookmark alloc] initWithProject:self URL:[fileURL URLByAppendingFragmentDictionary:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:line] forKey:@"line"]] note:note];
    [bookmarks addObject:bookmark];
    _dirty = YES;
    
    // Clearing cacheing dictionary entry
    if ([_fileToBookmarksCache count])
    {
        [_fileToBookmarksCache removeObjectForKey:[filePath substringFromIndex:[projectPath length]]];
    }
}

- (void)removeBookmark:(ProjectBookmark *)bookmark
{
    [bookmarks removeObject:bookmark];
    _dirty = YES;
    
    // Clearing cacheing dictionary entry
    if ([_fileToBookmarksCache count])
    {
        NSString *str = [[bookmark.URL path] substringFromIndex:[[self.URL path] length] + 1];
        [_fileToBookmarksCache removeObjectForKey:str];
    }
}

- (NSArray *)bookmarksForFile:(NSURL *)fileURL atLine:(NSUInteger)lineNumber
{
    NSString *filePath = [[fileURL URLByStandardizingPath] absoluteString];
    NSString *projectPath = [self.URL absoluteString];
    ECASSERT([filePath hasPrefix:projectPath]);
    filePath = [filePath substringFromIndex:[projectPath length]];
    
    NSMutableArray *result = nil;
    NSMutableArray *fileBookmarks = [_fileToBookmarksCache objectForKey:projectPath];
    
    // Using cached bookmarks
    for (ProjectBookmark *bookmark in fileBookmarks)
    {
        if ([bookmark line] == lineNumber)
        {
            if (!result)
                result = [NSMutableArray new];
            [result addObject:bookmark];
        }
    }
    if (result)
        return result;

    // Generate bookmarks collection for file
    for (ProjectBookmark *bookmark in bookmarks)
    {
        if (![bookmark.bookmarkPath hasPrefix:filePath])
            continue;
        
        if (!fileBookmarks)
            fileBookmarks = [NSMutableArray new];
        [fileBookmarks addObject:bookmark];
        
        if ([bookmark line] == lineNumber)
        {
            if (!result)
                result = [NSMutableArray new];
            [result addObject:bookmark];
        }
    }
    
    // Prepare cacheing dictionary
    if (fileBookmarks)
    {
        if (!_fileToBookmarksCache)
            _fileToBookmarksCache = [NSMutableDictionary new];
        [_fileToBookmarksCache setObject:fileBookmarks forKey:filePath];
    }
    
    return result;
}

#pragma mark Remotes methods

- (void)addRemote:(ProjectRemote *)remote
{
    NSIndexSet *addSet = [NSIndexSet indexSetWithIndex:[remotes count]];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:addSet forKey:@"remotes"];
    if (!remotes)
        remotes = [NSMutableArray new];
    [remotes addObject:remote];
    _dirty = YES;
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:addSet forKey:@"remotes"];
}

- (void)removeRemote:(ProjectRemote *)remote
{
    NSUInteger removeIndex = [remotes indexOfObject:remote];
    if (removeIndex == NSNotFound)
        return;
    NSIndexSet *removeSet = [NSIndexSet indexSetWithIndex:removeIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:removeSet forKey:@"remotes"];
    [remotes removeObject:remote];
    _dirty = YES;
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:removeSet forKey:@"remotes"];
}

#pragma mark Class methods

+ (void)saveProjectsToDisk
{
    [openProjects enumerateKeysAndObjectsUsingBlock:^(id key, ArtCodeProject *project, BOOL *stop) {
        [project flush];
    }];
}

+ (BOOL)projectWithNameExists:(NSString *)name
{
    if (![name hasSuffix:ProjectExtension])
        name = [name stringByAppendingString:ProjectExtension];
    
    BOOL isDirectory = NO;
    BOOL exists =[[NSFileManager new] fileExistsAtPath:[[[ArtCodeURL projectsDirectory] URLByAppendingPathComponent:name isDirectory:YES] path] isDirectory:&isDirectory];
    return exists && isDirectory;
}

+ (NSString *)validNameForNewProjectName:(NSString *)name
{
    name = [name stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    
    NSFileManager *new = [NSFileManager new];
    NSString *projectsPath = [[ArtCodeURL projectsDirectory] path];
    
    NSUInteger count = 0;
    NSString *result = name;
    while ([new fileExistsAtPath:[projectsPath stringByAppendingPathComponent:[result stringByAppendingString:ProjectExtension]]])
    {
        result = [name stringByAppendingFormat:@" (%u)", ++count];
    }
    return result;
}

+ (NSURL *)projectURLFromName:(NSString *)name
{
    if (![name hasSuffix:ProjectExtension])
        name = [name stringByAppendingString:ProjectExtension];
    
    return [[ArtCodeURL projectsDirectory] URLByAppendingPathComponent:name];
}

+ (id)projectWithName:(NSString *)name
{
    name = [name stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    if (![name hasSuffix:ProjectExtension])
        name = [name stringByAppendingString:ProjectExtension];
    
    NSURL *projectUrl = [[ArtCodeURL projectsDirectory] URLByAppendingPathComponent:name isDirectory:YES];
    
    if (!openProjects)
        openProjects = [WeakDictionary new];
    
    id project = [openProjects objectForKey:projectUrl];
    if (project)
        return project;
    
    // Create project direcotry
    if (![[NSFileManager new] fileExistsAtPath:[projectUrl path]])
    {
        return nil;
    }
    
    // Open project
    project = [[self alloc] initWithURL:projectUrl];
    [openProjects setObject:project forKey:projectUrl];
    return project;
}

+ (id)projectWithURL:(NSURL *)url
{
    ECASSERT(url != nil);
    
    NSString *projectName = [ArtCodeURL projectNameFromURL:url isProjectRoot:NULL];
    if (!projectName)
        return nil;
    
    return [self projectWithName:projectName];
}

+ (id)createProjectWithName:(NSString *)name
{
    name = [name stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    if (![name hasSuffix:ProjectExtension])
        name = [name stringByAppendingString:ProjectExtension];
    
    NSURL *projectUrl = [[ArtCodeURL projectsDirectory] URLByAppendingPathComponent:name isDirectory:YES];
    
    if (!openProjects)
        openProjects = [WeakDictionary new];
    
    id project = [openProjects objectForKey:projectUrl];
    if (project)
        return project;
    
    // Create project direcotry
    if (![[NSFileManager new] fileExistsAtPath:[projectUrl path]])
    {
        [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:projectUrl options:0 error:NULL byAccessor:^(NSURL *newURL) {
            [[NSFileManager new] createDirectoryAtURL:projectUrl withIntermediateDirectories:YES attributes:nil error:NULL];
        }];
    }
    
    // Open project
    project = [[self alloc] initWithURL:projectUrl];
    [openProjects setObject:project forKey:projectUrl];
    return project;
}

+ (id)createProjectWithName:(NSString *)name fromArchiveURL:(NSURL *)archiveURL
{
    name = [self validNameForNewProjectName:name];                                 
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:archiveURL options:0 writingItemAtURL:[self projectURLFromName:name] options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        [[NSFileManager new] createDirectoryAtURL:newWritingURL withIntermediateDirectories:YES attributes:nil error:NULL];
        [ArchiveUtilities extractArchiveAtURL:newReadingURL toDirectory:newWritingURL];
    }];
    
    return [self createProjectWithName:name];
}

@end


@implementation ProjectBookmark

@synthesize bookmarkPath, project, note, line;

- (NSURL *)URL
{
    return [NSURL URLWithString:bookmarkPath relativeToURL:project.URL];
}

- (NSInteger)line
{
    if (line < 0)
        line = [[[self.URL fragmentDictionary] objectForKey:@"line"] integerValue];
    return line;
}

#pragma mark Private methods

- (id)initWithProject:(ArtCodeProject *)aProject URL:(NSURL *)aUrl note:(NSString *)aNote
{
    self = [super init];
    if (!self)
        return nil;
    
    ECASSERT(aProject != nil && aUrl != nil);
    
    project = aProject;
    bookmarkPath = [[aUrl absoluteString] substringFromIndex:[[aProject.URL absoluteString] length]];
    note = aNote;
    line = -1;
    
    return self;
}

- (id)initWithProject:(ArtCodeProject *)aProject propertyDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self)
        return nil;
    
    project = aProject;
    bookmarkPath = [dictionary objectForKey:@"URL"];
    note = [dictionary objectForKey:@"note"];
    line = -1;
    
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

- (NSString *)description
{
    NSUInteger bookmarkLine = [self line];
    if (bookmarkLine != 0)
    {
        NSInteger fragmentLocation = [self.bookmarkPath rangeOfString:@"#"].location;
        if (fragmentLocation != NSNotFound)
        {
            return [[self.bookmarkPath substringToIndex:fragmentLocation] stringByAppendingFormat:@" - Line: %u", bookmarkLine];
        }
        else
        {
            return [self.bookmarkPath stringByAppendingFormat:@" - Line: %u", bookmarkLine];
        }
    }
    else
    {
        return self.bookmarkPath;
    }
}

@end

@implementation ProjectRemote

@synthesize name, scheme, host, port, user;

- (void)setPassword:(NSString *)password
{
    [[Keychain sharedKeychain] setPassword:password forServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:scheme host:host port:port] account:user];
}

- (NSString *)password
{
    return [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:scheme host:host port:port] account:user];
}

- (id)initWithPropertyDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (!self)
        return nil;
    name = [dict objectForKey:@"name"];
    scheme = [dict objectForKey:@"scheme"];
    host = [dict objectForKey:@"host"];
    port = [[dict objectForKey:@"port"] integerValue];
    user = [dict objectForKey:@"user"];
    return self;
}

- (NSDictionary *)propertyDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", scheme, @"scheme", host, @"host", [NSString stringWithFormat:@"%d", port], @"port", user, @"user", nil];
}

- (NSURL *)URL
{
    NSString *portString = port ? [NSString stringWithFormat:@":%d", port] : @"";
    return [user length] ? [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@@%@%@", scheme, user, host, portString]] : [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", scheme, host, portString]];
}

@end
