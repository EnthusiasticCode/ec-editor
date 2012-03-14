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

static NSMutableSet *_projectUUIDs;

/// UUID to dictionary of cached projects informations (uuid, path, labelColor, name).
static NSMutableDictionary *_projectsList = nil;

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _projectPlistFileName = @".acproj";
static NSString * const _contentsFolderName = @"Contents";

static NSString * const _projectsListKey = @"ACProjectProjectsList";
static NSString * const _plistUUIDKey = @"uuid";
static NSString * const _plistPathKey = @"path";
static NSString * const _plistNameKey = @"name";
static NSString * const _plistLabelColorKey = @"labelColor";
static NSString * const _plistContentsKey = @"contents";
static NSString * const _plistBookmarksKey = @"bookmarks";
static NSString * const _plistRemotesKey = @"remotes";

@interface ACProject ()

/// The local URL at which all projects are stored.
+ (NSURL *)_projectsDirectory;

/// Project metadata getters and setters
+ (NSString *)_nameForProject:(ACProject *)project;
+ (void)_setName:(NSString *)name forProject:(ACProject *)project;
+ (UIColor *)_labelColorForProject:(ACProject *)project;
+ (void)_setLabelColor:(UIColor *)color forProject:(ACProject *)project;

/// Designated initializer
- (id)_initWithUUID:(NSString *)uuid;

@end

#pragma mark

/// Remotes internal inialization for creation
@interface ACProjectRemote (Internal)

- (id)initWithProject:(ACProject *)project name:(NSString *)name URL:(NSURL *)remoteURL;

@end

#pragma mark

@implementation ACProject
{
    BOOL _isDirty;
    NSMutableDictionary *_filesCache;
    NSMutableDictionary *_bookmarksCache;
    NSMutableDictionary *_remotes;
}

@synthesize UUID = _UUID, artCodeURL = _artCodeURL;
@synthesize contentsFolder = _contentsFolder;

#pragma mark - NSObject

+ (void)initialize
{
    if (self != [ACProject class])
        return;
    
    _projectUUIDs = [[NSMutableSet alloc] init];
    
    // Ensure that projects URL exists
    [[[NSFileManager alloc] init] createDirectoryAtURL:[self _projectsDirectory] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Loads the saved projects informations from user defaults
    _projectsList = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:_projectsListKey] mutableCopy];
    if (!_projectsList)
    {
        _projectsList = [NSMutableDictionary new];
        [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
    }
}

#pragma mark - UIDocument

- (id)initWithFileURL:(NSURL *)url
{
    UNIMPLEMENTED(); // Designated initializer is _initWithUUID:
}

- (NSUndoManager *)undoManager {
    return nil;
}

- (BOOL)hasUnsavedChanges {
    return _isDirty;
}

- (void)updateChangeCount:(UIDocumentChangeKind)change {
    ECASSERT(change == UIDocumentChangeDone);
    _isDirty = YES;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSFileWrapper *bundleWrapper = (NSFileWrapper *)contents;
    __block NSFileWrapper *contentsWrapper = nil;
    __block NSDictionary *plist = nil;
    
    [[bundleWrapper fileWrappers] enumerateKeysAndObjectsUsingBlock:^(NSString *fileName, NSFileWrapper *fileWrapper, BOOL *stop) {
        if ([fileName isEqualToString:_projectPlistFileName]) {
            ECASSERT([fileWrapper isRegularFile]);
            plist = [NSPropertyListSerialization propertyListWithData:[fileWrapper regularFileContents] options:NSPropertyListImmutable format:NULL error:outError];
        } else if([fileName isEqualToString:_contentsFolderName]) {
            contentsWrapper = fileWrapper;
        }
    }];
    
    // Project's content
    if (contentsWrapper) {
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:[plist objectForKey:_plistContentsKey] parent:nil contents:contentsWrapper];
    }
    
    // Remotes
    if ([plist objectForKey:_plistRemotesKey]) {
        NSMutableDictionary *remotesFromPlist = [NSMutableDictionary new];
        for (NSDictionary *remotePlist in [plist objectForKey:_plistRemotesKey]) {
            ACProjectRemote *remote = [[ACProjectRemote alloc] initWithProject:self propertyListDictionary:remotePlist];
            if (remote) {
                [remotesFromPlist setObject:remote forKey:remote.UUID];
            }
        }
        _remotes = [remotesFromPlist copy];
    }
    
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    // Creating project plist
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
    
    // Creating project contents wrapper
    NSFileWrapper *contentsWrapper = [self.contentsFolder contents];
    contentsWrapper.preferredFilename = _contentsFolderName;
    
    // Filesystem content
    if (contentsWrapper) {
        NSDictionary *contentsPlist = self.contentsFolder.propertyListDictionary;
        if (contentsPlist) {
            [plist setObject:contentsPlist forKey:_plistContentsKey];
        }
    }

    // Remotes
    if ([self.remotes count]) {
        NSMutableArray *remotesPlist = [NSMutableArray arrayWithCapacity:[self.remotes count]];
        for (ACProjectFileBookmark *remote in self.remotes) {
            [remotesPlist addObject:[remote propertyListDictionary]];
        }
        [plist setObject:remotesPlist forKey:_plistRemotesKey];
    }
    
    // Creating project plist wrapper
    NSFileWrapper *plistWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:outError]];
    plistWrapper.preferredFilename = _projectPlistFileName;
    
    
    // Creating project bundle wrapper
    NSFileWrapper *bundleWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    if (contentsWrapper) {
        [bundleWrapper addFileWrapper:contentsWrapper];
    }
    if (plistWrapper) {
        [bundleWrapper addFileWrapper:plistWrapper];
    }
    
    return bundleWrapper;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    NSLog(@">>>>>>>>>>>>>>>>> %@", error);
}

#pragma mark - Projects list

+ (ACProject *)projectWithUUID:(id)uuid {
    NSDictionary *projectInfo = [_projectsList objectForKey:uuid];
    if (!projectInfo || ![projectInfo objectForKey:_plistPathKey])
        return nil;
    return [[self alloc] _initWithUUID:uuid];
}

+ (void)createProjectWithName:(NSString *)name importArchiveURL:(NSURL *)archiveURL completionHandler:(void (^)(ACProject *))completionHandler {
    // Create the project
    NSURL *projectURL = [[self _projectsDirectory] URLByAppendingPathComponent:[name stringByAppendingPathExtension:@"acproj"]];
    ACProject *project = [[self alloc] initWithFileURL:projectURL];
    [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        // Inform the completion handler
        if (completionHandler)
            completionHandler(success ? project : nil);
    }];
}

#pragma mark - Project metadata

- (id)UUID {
    return self.fileURL.lastPathComponent.stringByDeletingPathExtension;
}

- (NSURL *)artCodeURL {
    if (!_artCodeURL) {
        _artCodeURL = [ArtCodeURL artCodeURLWithProject:self item:nil path:nil];
    }
    return _artCodeURL;
}

- (NSString *)name {
    return [[self class] _nameForProject:self];
}

- (void)setName:(NSString *)name {
    [[self class] _setName:name forProject:self];
}

- (UIColor *)labelColor {
    return [[self class] _labelColorForProject:self];
}

- (void)setLabelColor:(UIColor *)value {
    [[self class] _setLabelColor:value forProject:self];
}

#pragma mark - Project content

- (ACProjectFolder *)contentsFolder {
    if (!_contentsFolder && !self.documentState & UIDocumentStateClosed) {
        NSFileWrapper *contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        contents.preferredFilename = _contentsFolderName;
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:nil parent:nil contents:contents];
        [self updateChangeCount:UIDocumentChangeDone];
    }
    return _contentsFolder;
}

- (NSArray *)files {
    return [_filesCache allValues];
}

- (NSArray *)bookmarks {
    return [_bookmarksCache allValues];
}

- (NSArray *)remotes {
    return [_remotes allValues];
}

- (ACProjectItem *)itemWithUUID:(id)uuid {
    ACProjectItem *item = [_filesCache objectForKey:uuid];
    if (!item) {
        item = [_bookmarksCache objectForKey:uuid];
    }
    if (!item) {
        item = [_remotes objectForKey:uuid];
    }
    return item;
}

- (ACProjectRemote *)addRemoteWithName:(NSString *)name URL:(NSURL *)remoteURL {
    ACProjectRemote *remote = [[ACProjectRemote alloc] initWithProject:self name:name URL:remoteURL];
    if (!remote) {
        return nil;
    }
    [self willChangeValueForKey:@"remotes"];
    [_remotes setObject:remote forKey:remote.UUID];
    [self updateChangeCount:UIDocumentChangeDone];
    [self didChangeValueForKey:@"remotes"];
    return remote;
}

#pragma mark - Internal Remotes Methods

- (void)didRemoveRemote:(ACProjectRemote *)remote {
    ECASSERT(remote);
    [self willChangeValueForKey:@"remotes"];
    [_remotes removeObjectForKey:remote.UUID];
    [self didChangeValueForKey:@"remotes"];
}

#pragma mark - Internal Bookmarks Methods

- (void)didAddBookmark:(ACProjectFileBookmark *)bookmark {
    ECASSERT(bookmark);
    [self willChangeValueForKey:@"bookmarks"];
    [_bookmarksCache setObject:bookmark forKey:bookmark.UUID];
    [self didChangeValueForKey:@"bookmarks"];
}

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark {
    ECASSERT(bookmark);
    [self willChangeValueForKey:@"bookmarks"];
    [_bookmarksCache removeObjectForKey:bookmark.UUID];
    [self didChangeValueForKey:@"bookmarks"];
}

#pragma mark - Internal Files Methods

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem {
    // Called when adding a file and in loading phase
    ECASSERT(fileSystemItem);
    [self willChangeValueForKey:@"files"];
    [_filesCache setObject:fileSystemItem forKey:fileSystemItem.UUID];
    [self didChangeValueForKey:@"files"];
}

- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem {
    ECASSERT(fileSystemItem);
    [self willChangeValueForKey:@"files"];
    [_filesCache removeObjectForKey:fileSystemItem.UUID];
    [self didChangeValueForKey:@"files"];
}

#pragma mark - Private Methods

+ (NSURL *)_projectsDirectory {
    static NSURL *_projectsDirectory = nil;
    if (!_projectsDirectory) {
        _projectsDirectory = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_projectsFolderName isDirectory:YES];
    }
    return _projectsDirectory;
}

+ (UIColor *)_labelColorForProject:(ACProject *)project {
    NSString *hexString = [[_projectsList objectForKey:project.UUID] objectForKey:_plistLabelColorKey];
    UIColor *labelColor = nil;
    if ([hexString length]) {
        labelColor = [UIColor colorWithHexString:hexString];
    }
    return labelColor;
}

+ (void)_setLabelColor:(UIColor *)color forProject:(ACProject *)project {
    [project willChangeValueForKey:@"labelColor"];
    NSMutableDictionary *projectInfo = [[_projectsList objectForKey:project.UUID] mutableCopy];
    [projectInfo setValue:color.hexString forKey:_plistLabelColorKey];
    [_projectsList setObject:projectInfo forKey:project.UUID];
    [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
    [project didChangeValueForKey:@"labelColor"];
}

- (id)_initWithUUID:(NSString *)uuid {
    self = [super initWithFileURL:[[[self class] _projectsDirectory] URLByAppendingPathComponent:uuid]];
    if (!self)
        return nil;
    _filesCache = [NSMutableDictionary new];
    _bookmarksCache = [NSMutableDictionary new];
    _remotes = [NSMutableDictionary new];
    return self;
}

@end
