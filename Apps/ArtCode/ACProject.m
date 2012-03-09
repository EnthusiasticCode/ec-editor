//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject+Internal.h"
#import "ACProjectFolder.h"
#import "ACProjectFileBookmark.h"
#import "ACProjectRemote+Internal.h"

#import "ACProjectItem+Internal.h"
#import "ACProjectFileSystemItem+Internal.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"

/// UUID to dictionary of cached projects informations (uuid, path, labelColor, localizedName).
static NSMutableDictionary *_projectCachedInfos = nil;

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _projectsCachedInfoFileName = @".acprojcache";
static NSString * const _projectPlistFileName = @".acproj";
static NSString * const _contentsFolderName = @"Contents";

@implementation ACProject {
    BOOL _isDirty;
    NSMutableDictionary *_files;
    NSMutableDictionary *_remotes;
    NSMutableDictionary *_bookmarks;
}

#pragma mark - Properties

@synthesize UUID = _UUID, labelColor = _labelColor;
@synthesize contentsFolder = _contentsFolder;

- (id)UUID
{
    // Retrieve UUID from cache if possible
    if (self.documentState & UIDocumentStateClosed)
    {
        [_projectCachedInfos enumerateKeysAndObjectsUsingBlock:^(id uuid, NSDictionary *info, BOOL *stop) {
            if ([[info objectForKey:@"localizedName"] isEqualToString:self.localizedName])
            {
                _UUID = uuid;
                *stop = YES;
            }
        }];
    }
    // Generate an UUID on a new project
    else if (!_UUID)
    {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
        _UUID = (__bridge NSString *)uuidString;
        CFRelease(uuidString);
        CFRelease(uuid);
        [self updateChangeCount:UIDocumentChangeDone];
    }
    return _UUID;
}

- (UIColor *)labelColor
{
    // Retrieve labelColor from cache if possible
    if (!_labelColor && self.documentState & UIDocumentStateClosed)
    {
        [_projectCachedInfos enumerateKeysAndObjectsUsingBlock:^(id uuid, NSDictionary *info, BOOL *stop) {
            if ([[info objectForKey:@"localizedName"] isEqualToString:self.localizedName])
            {
                NSString *labelColorString = [info objectForKey:@"labelColor"];
                if ([labelColorString length])
                    _labelColor = [UIColor colorWithHexString:labelColorString];
                *stop = YES;
            }
        }];
    }
    return _labelColor;
}

- (void)setLabelColor:(UIColor *)value
{
    if (value == _labelColor)
        return;
    
    _labelColor = value;
    [self updateChangeCount:UIDocumentChangeDone];
}

- (ACProjectFolder *)contentsFolder
{
    if (!_contentsFolder && !self.documentState & UIDocumentStateClosed)
    {
        NSFileWrapper *contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        contents.preferredFilename = _contentsFolderName;
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:nil parent:nil contents:contents];
        [self updateChangeCount:UIDocumentChangeDone];
    }
    return _contentsFolder;
}

- (NSArray *)files
{
    return [_files allValues];
}

- (NSArray *)bookmarks
{
    return [_bookmarks allValues];
}

- (NSArray *)remotes
{
    return [_remotes allValues];
}

- (id)initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    if (!self)
        return nil;
    _files = [NSMutableDictionary new];
    _bookmarks = [NSMutableDictionary new];
    _remotes = [NSMutableDictionary new];
    return self;
}

#pragma mark - UIDocument

- (NSUndoManager *)undoManager
{
    return nil;
}

- (BOOL)hasUnsavedChanges
{
    return _isDirty;
}

- (void)updateChangeCount:(UIDocumentChangeKind)change
{
    ECASSERT(change == UIDocumentChangeDone);
    _isDirty = YES;
    [[self class] updateCacheForProject:self];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSFileWrapper *bundleWrapper = (NSFileWrapper *)contents;
    __block NSFileWrapper *contentsWrapper = nil;
    __block NSDictionary *plist = nil;
    
    [[bundleWrapper fileWrappers] enumerateKeysAndObjectsUsingBlock:^(NSString *fileName, NSFileWrapper *fileWrapper, BOOL *stop) {
        if ([fileName isEqualToString:_projectPlistFileName])
        {
            ECASSERT([fileWrapper isRegularFile]);
            plist = [NSPropertyListSerialization propertyListWithData:[fileWrapper regularFileContents] options:NSPropertyListImmutable format:NULL error:outError];
        }
        else if([fileName isEqualToString:_contentsFolderName])
        {
            contentsWrapper = fileWrapper;
        }
    }];
    
    // Project's properties
    _UUID = [plist objectForKey:@"uuid"];
    if ([plist objectForKey:@"labelColor"])
        _labelColor = [UIColor colorWithHexString:[plist objectForKey:@"labelColor"]];
    
    // Project's content
    if (contentsWrapper)
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:[plist objectForKey:@"contents"] parent:nil contents:contentsWrapper];
    
    // Bookmarks
    if ([plist objectForKey:@"bookmarks"])
    {
        NSMutableDictionary *bookmarksFromPlist = [NSMutableDictionary new];
        for (NSDictionary *bookmarkPlist in [plist objectForKey:@"bookmarks"])
        {
            ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self propertyListDictionary:bookmarkPlist];
            if (bookmark)
                [bookmarksFromPlist setObject:bookmark forKey:bookmark.UUID];
        }
        _bookmarks = [bookmarksFromPlist copy];
    }
    
    // Remotes
    if ([plist objectForKey:@"remotes"])
    {
        NSMutableDictionary *remotesFromPlist = [NSMutableDictionary new];
        for (NSDictionary *remotePlist in [plist objectForKey:@"remotes"])
        {
            ACProjectRemote *remote = [[ACProjectRemote alloc] initWithProject:self propertyListDictionary:remotePlist];
            if (remote)
                [remotesFromPlist setObject:remote forKey:remote.UUID];
        }
        _remotes = [remotesFromPlist copy];
    }
    
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    // Creating project plist
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
    
    // Creating project contents wrapper
    NSFileWrapper *contentsWrapper = [self.contentsFolder contents];
    contentsWrapper.preferredFilename = _contentsFolderName;
    
    // Project properties
    if (self.UUID)
        [plist setObject:self.UUID forKey:@"uuid"];
    if (self.labelColor)
        [plist setObject:[self.labelColor hexString] forKey:@"labelColor"];
    
    // Filesystem content
    if (contentsWrapper)
    {
        NSDictionary *contentsPlist = self.contentsFolder.propertyListDictionary;
        if (contentsPlist)
            [plist setObject:contentsPlist forKey:@"contents"];
    }

    // Bookmarks
    if ([self.bookmarks count])
    {
        NSMutableArray *bookmarksPlist = [NSMutableArray arrayWithCapacity:[self.bookmarks count]];
        for (ACProjectFileBookmark *bookmark in self.bookmarks)
        {
            [bookmarksPlist addObject:[bookmark propertyListDictionary]];
        }
        [plist setObject:bookmarksPlist forKey:@"bookmarks"];
    }
    
    // Remotes
    if ([self.remotes count])
    {
        NSMutableArray *remotesPlist = [NSMutableArray arrayWithCapacity:[self.remotes count]];
        for (ACProjectFileBookmark *remote in self.remotes)
        {
            [remotesPlist addObject:[remote propertyListDictionary]];
        }
        [plist setObject:remotesPlist forKey:@"remotes"];
    }
    
    // Creating project plist wrapper
    NSFileWrapper *plistWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:outError]];
    plistWrapper.preferredFilename = _projectPlistFileName;
    
    
    // Creating project bundle wrapper
    NSFileWrapper *bundleWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    if (contentsWrapper)
        [bundleWrapper addFileWrapper:contentsWrapper];
    if (plistWrapper)
        [bundleWrapper addFileWrapper:plistWrapper];
    
    return bundleWrapper;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSLog(@">>>>>>>>>>>>>>>>> %@", error);
}

#pragma mark - Class Methods

+ (void)initialize
{
    // Loads the chached projects informations from plist
    _projectCachedInfos = [NSMutableDictionary new];
    NSURL *cacheFileURL = [[self projectsURL] URLByAppendingPathComponent:_projectsCachedInfoFileName];
    if ([[NSFileManager new] fileExistsAtPath:cacheFileURL.path])
    {
        for (NSDictionary *info in [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:cacheFileURL] options:NSPropertyListImmutable format:nil error:NULL])
        {
            if ([info objectForKey:@"uuid"])
                [_projectCachedInfos setObject:info forKey:[info objectForKey:@"uuid"]];
        }
    }
}

+ (void)updateCacheForProject:(ACProject *)project
{
    // Updates the entry for a project's cache
    ECASSERT(_projectCachedInfos);
    ECASSERT([project documentState] & UIDocumentStateNormal);
    [_projectCachedInfos setObject:[NSDictionary dictionaryWithObjectsAndKeys:project.UUID, @"uuid", [project.fileURL lastPathComponent], @"path", project.localizedName, @"localizedName", [project.labelColor hexString], @"labelColor", nil] forKey:project.UUID];
}

+ (void)prepareForBackground
{
    // Saves cached projects informations plist
    if (![_projectCachedInfos count])
        return;
    [[NSPropertyListSerialization dataWithPropertyList:[_projectCachedInfos allValues] format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL] writeToURL:[[self projectsURL] URLByAppendingPathComponent:_projectsCachedInfoFileName] atomically:YES];
}

+ (ACProject *)projectWithUUID:(id)uuid
{
    NSDictionary *projectInfo = [_projectCachedInfos objectForKey:uuid];
    if (!projectInfo || ![projectInfo objectForKey:@"path"])
        return nil;
    return [[ACProject alloc] initWithFileURL:[[self projectsURL] URLByAppendingPathComponent:[projectInfo objectForKey:@"path"]]];
}

+ (NSURL *)projectsURL
{
    static NSURL *_projectsURL = nil;
    if (!_projectsURL)
        _projectsURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_projectsFolderName isDirectory:YES];
    return _projectsURL;
}

+ (void)createProjectWithName:(NSString *)name importArchiveURL:(NSURL *)archiveURL completionHandler:(void (^)(ACProject *))completionHandler
{
    // Ensure that projects URL exists
    [[NSFileManager new] createDirectoryAtURL:[self projectsURL] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Create the project
    NSURL *projectURL = [[self projectsURL] URLByAppendingPathComponent:[name stringByAppendingPathExtension:@"acproj"]];
    ACProject *project = [[ACProject alloc] initWithFileURL:projectURL];
    [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        // Inform the completion handler
        if (completionHandler)
            completionHandler(success ? project : nil);
    }];
}

#pragma mark - Public Methods

- (ACProjectItem *)itemWithUUID:(id)uuid
{
    ACProjectItem *item = [_files objectForKey:uuid];
    if (!item)
        item = [_bookmarks objectForKey:uuid];
    if (!item)
        item = [_remotes objectForKey:uuid];
    return item;
}

- (void)addRemoteWithName:(NSString *)name URL:(NSURL *)remoteURL
{
    ACProjectRemote *remote = [[ACProjectRemote alloc] initWithProject:self name:name URL:remoteURL];
    if (!remote)
        return;
    [_remotes setObject:remote forKey:remote.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - Internal Methods

- (void)removeRemote:(id)remoteUUID
{
    ECASSERT(remoteUUID);
    [_remotes removeObjectForKey:remoteUUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

- (void)didAddBookmark:(ACProjectFileBookmark *)bookmark
{
    ECASSERT(bookmark);
    [_bookmarks setObject:bookmark forKey:bookmark.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark
{
    ECASSERT(bookmark);
    [_bookmarks removeObjectForKey:bookmark.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem
{
    ECASSERT(fileSystemItem);
    [_files setObject:fileSystemItem forKey:fileSystemItem.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem
{
    ECASSERT(fileSystemItem);
    [_files removeObjectForKey:fileSystemItem.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

@end
