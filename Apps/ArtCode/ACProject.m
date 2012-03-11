//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACProjectFolder.h"
#import "ACProjectFileBookmark.h"
#import "ACProjectRemote.h"

#import "ACProjectItem+Internal.h"
#import "ACProjectFileSystemItem+Internal.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"

#import "ArtCodeURL.h"

/// UUID to dictionary of cached projects informations (uuid, path, labelColor, localizedName).
static NSMutableDictionary *_projectsList = nil;

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _projectPlistFileName = @".acproj";
static NSString * const _contentsFolderName = @"Contents";

static NSString * const _projectsListKey = @"ACProjectProjectsList";
static NSString * const _plistUUIDKey = @"uuid";
static NSString * const _plistPathKey = @"path";
static NSString * const _plistLocalizedNameKey = @"localizedName";
static NSString * const _plistLabelColorKey = @"labelColor";
static NSString * const _plistContentsKey = @"contents";
static NSString * const _plistBookmarksKey = @"bookmarks";
static NSString * const _plistRemotesKey = @"remotes";

@interface ACProject ()

/// Updates and saves the projects informations cache with data from the provided project.
+ (void)_updateCacheForProject:(ACProject *)project;
+ (id)_uuidForProject:(ACProject *)project;
+ (UIColor *)_labelColorForProject:(ACProject *)project;
+ (void)_setLabelColor:(UIColor *)color forProject:(ACProject *)project;

@end

/// Bookmark internal initialization for creation
@interface ACProjectFileBookmark (Internal)

- (id)initWithProject:(ACProject *)project file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint;

@end

/// Remotes internal inialization for creation
@interface ACProjectRemote (Internal)

- (id)initWithProject:(ACProject *)project name:(NSString *)name URL:(NSURL *)remoteURL;

@end


@implementation ACProject
{
    BOOL _isDirty;
    NSMutableDictionary *_files;
    NSMutableDictionary *_remotes;
    NSMutableDictionary *_bookmarks;
}

#pragma mark - Properties

@synthesize UUID = _UUID, artCodeURL = _artCodeURL;
@synthesize contentsFolder = _contentsFolder;

- (id)UUID
{    
    if (!_UUID)
    {
        _UUID = [ACProject _uuidForProject:self];
    }
    return _UUID;
}

- (NSURL *)artCodeURL
{
    if (!_artCodeURL)
    {
        if (self.UUID)
            _artCodeURL = [ArtCodeURL artCodeURLWithProject:self item:nil path:nil];
    }
    return _artCodeURL;
}

+ (NSSet *)keyPathsForValuesAffectingArtCodeURL
{
    return [NSSet setWithObject:@"UUID"];
}

- (UIColor *)labelColor
{
    return [ACProject _labelColorForProject:self];
}

- (void)setLabelColor:(UIColor *)value
{
    [ACProject _setLabelColor:value forProject:self];
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
}

- (NSString *)localizedName
{
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

+ (NSSet *)keyPathsForValuesAffectingLocalizedName
{
    return [NSSet setWithObject:@"fileURL"];
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
    
    // Project's content
    if (contentsWrapper)
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:[plist objectForKey:_plistContentsKey] parent:nil contents:contentsWrapper];
    
    // Bookmarks
    if ([plist objectForKey:_plistBookmarksKey])
    {
        NSMutableDictionary *bookmarksFromPlist = [NSMutableDictionary new];
        for (NSDictionary *bookmarkPlist in [plist objectForKey:_plistBookmarksKey])
        {
            ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self propertyListDictionary:bookmarkPlist];
            if (bookmark)
                [bookmarksFromPlist setObject:bookmark forKey:bookmark.UUID];
        }
        _bookmarks = [bookmarksFromPlist copy];
    }
    
    // Remotes
    if ([plist objectForKey:_plistRemotesKey])
    {
        NSMutableDictionary *remotesFromPlist = [NSMutableDictionary new];
        for (NSDictionary *remotePlist in [plist objectForKey:_plistRemotesKey])
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
    
    // Filesystem content
    if (contentsWrapper)
    {
        NSDictionary *contentsPlist = self.contentsFolder.propertyListDictionary;
        if (contentsPlist)
            [plist setObject:contentsPlist forKey:_plistContentsKey];
    }

    // Bookmarks
    if ([self.bookmarks count])
    {
        NSMutableArray *bookmarksPlist = [NSMutableArray arrayWithCapacity:[self.bookmarks count]];
        for (ACProjectFileBookmark *bookmark in self.bookmarks)
        {
            [bookmarksPlist addObject:[bookmark propertyListDictionary]];
        }
        [plist setObject:bookmarksPlist forKey:_plistBookmarksKey];
    }
    
    // Remotes
    if ([self.remotes count])
    {
        NSMutableArray *remotesPlist = [NSMutableArray arrayWithCapacity:[self.remotes count]];
        for (ACProjectFileBookmark *remote in self.remotes)
        {
            [remotesPlist addObject:[remote propertyListDictionary]];
        }
        [plist setObject:remotesPlist forKey:_plistRemotesKey];
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
    // Loads the saved projects informations from user defaults
    _projectsList = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:_projectsListKey] mutableCopy];
    if (!_projectsList)
    {
        _projectsList = [NSMutableDictionary new];
        [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
    }
}

+ (id)_uuidForProject:(ACProject *)project
{
    __block id projectUUID = nil;
    [_projectsList enumerateKeysAndObjectsUsingBlock:^(id uuid, NSDictionary *info, BOOL *stop) {
        if ([[info objectForKey:_plistLocalizedNameKey] isEqualToString:project.localizedName])
        {
            projectUUID = uuid;
            *stop = YES;
        }
    }];
    if (!projectUUID)
    {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
        projectUUID = (__bridge NSString *)uuidString;
        CFRelease(uuidString);
        CFRelease(uuid);
        // The label color is nil if we're here
        [_projectsList setObject:[NSDictionary dictionaryWithObjectsAndKeys:projectUUID, _plistUUIDKey, project.fileURL.lastPathComponent, _plistPathKey, project.localizedName, _plistLocalizedNameKey, nil] forKey:projectUUID];
        [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
    }
    return projectUUID;
}

+ (ACProject *)projectWithUUID:(id)uuid
{
    NSDictionary *projectInfo = [_projectsList objectForKey:uuid];
    if (!projectInfo || ![projectInfo objectForKey:_plistPathKey])
        return nil;
    return [[ACProject alloc] initWithFileURL:[[self projectsURL] URLByAppendingPathComponent:[projectInfo objectForKey:_plistPathKey]]];
}

+ (UIColor *)_labelColorForProject:(ACProject *)project
{
    NSString *hexString = [[_projectsList objectForKey:project.UUID] objectForKey:_plistLabelColorKey];
    UIColor *labelColor = nil;
    if ([hexString length])
        labelColor = [UIColor colorWithHexString:hexString];
    return labelColor;
}

+ (void)_setLabelColor:(UIColor *)color forProject:(ACProject *)project
{
    NSMutableDictionary *projectInfo = [[_projectsList objectForKey:project.UUID] mutableCopy];
    [projectInfo setValue:color.hexString forKey:_plistLabelColorKey];
    [_projectsList setObject:projectInfo forKey:project.UUID];
    [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
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

#pragma mark - Internal Remotes Methods

- (void)didRemoveRemote:(ACProjectRemote *)remote
{
    ECASSERT(remote);
    [_remotes removeObjectForKey:remote.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - Internal Bookmarks Methods

- (void)didAddBookmarkWithFile:(ACProjectFile *)file point:(id)point
{
    ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self file:file bookmarkPoint:point];
    [_bookmarks setObject:bookmark forKey:bookmark.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark
{
    [_bookmarks removeObjectForKey:bookmark.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
}

- (NSArray *)implBookmarksForFile:(ACProjectFile *)file
{
    NSMutableArray *fileBookmarks = [NSMutableArray new];
    [_bookmarks enumerateKeysAndObjectsUsingBlock:^(id key, ACProjectFileBookmark *bookmark, BOOL *stop) {
        if (bookmark.file == file)
        {
            [fileBookmarks addObject:bookmark];
        }
    }];
    return [fileBookmarks copy];
}

#pragma mark - Internal Files Methods

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem
{
    ECASSERT(fileSystemItem);
    [_files setObject:fileSystemItem forKey:fileSystemItem.UUID];
}

- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem
{
    ECASSERT(fileSystemItem);
    [_files removeObjectForKey:fileSystemItem.UUID];
}

@end
