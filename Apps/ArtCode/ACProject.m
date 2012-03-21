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
#import "NSString+UUID.h"

#import "ArtCodeURL.h"

NSString * const ACProjectWillInsertProjectNotificationName = @"ACProjectWillInsertProjectNotificationName";
NSString * const ACProjectDidInsertProjectNotificationName = @"ACProjectDidInsertProjectNotificationName";
NSString * const ACProjectWillRemoveProjectNotificationName = @"ACProjectWillRemoveProjectNotificationName";
NSString * const ACProjectDidRemoveProjectNotificationName = @"ACProjectDidRemoveProjectNotificationName";
NSString * const ACProjectNotificationIndexKey = @"ACProjectNotificationIndexKey";

static NSMutableSet *_projectUUIDs;

/// UUID to dictionary of cached projects informations (uuid, path, labelColor, name).
static NSMutableDictionary *_projectsList = nil;

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _contentsFolderName = @"Contents";

// Metadata
static NSString * const _projectsListKey = @"ACProjectProjectsList";
static NSString * const _plistNameKey = @"name";
static NSString * const _plistLabelColorKey = @"labelColor";

// Content
static NSString * const _projectPlistFileName = @".acproj";
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

@implementation ACProject {
    BOOL _isDirty;
    NSMutableDictionary *_filesCache;
    NSMutableDictionary *_bookmarksCache;
    NSMutableDictionary *_remotes;
    NSError *_lastError;
}

@synthesize UUID = _UUID, artCodeURL = _artCodeURL;
@synthesize contentsFolder = _contentsFolder;

#pragma mark - NSObject

+ (void)initialize {
    if (self != [ACProject class])
        return;
    
    
    // Ensure that projects directory exists
    [[[NSFileManager alloc] init] createDirectoryAtURL:[self _projectsDirectory] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Loads the saved projects informations from user defaults
    _projectsList = (NSMutableDictionary *)[[NSUserDefaults standardUserDefaults] dictionaryForKey:_projectsListKey];
    
    // Checks projects on filesystem, adds missing projects to the project list, removes zombies
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSMutableDictionary *newProjectsList = [[NSMutableDictionary alloc] init];
    for (NSURL *projectURL in [fileManager contentsOfDirectoryAtURL:[self _projectsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL]) {
        NSString *uuid = projectURL.lastPathComponent;
        NSDictionary *projectInfo = [_projectsList objectForKey:uuid];
        if (projectInfo) {
            [newProjectsList setObject:projectInfo forKey:uuid];
        } else {
            projectInfo = [NSDictionary dictionaryWithObject:uuid forKey:_plistNameKey];
            [newProjectsList setObject:projectInfo forKey:uuid];
        }
    }
    _projectsList = newProjectsList;
    [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
    
    _projectUUIDs = [[NSMutableSet alloc] initWithArray:_projectsList.allKeys];
}

#pragma mark - UIDocument

- (id)initWithFileURL:(NSURL *)url {
    
    UNIMPLEMENTED(); // Designated initializer is _initWithUUID:
}

- (NSUndoManager *)undoManager {
    return nil;
}

- (BOOL)hasUnsavedChanges {
    return _isDirty;
}

- (void)updateChangeCount:(UIDocumentChangeKind)change {
    ASSERT(change == UIDocumentChangeDone);
    _isDirty = YES;
}

- (NSString *)localizedName {
    UNIMPLEMENTED(); // Use name instead
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)outError {
    // Read plist
    NSURL *plistURL = [url URLByAppendingPathComponent:_projectPlistFileName];
    NSData *plistData = [NSData dataWithContentsOfURL:plistURL options:NSDataReadingUncached error:outError];
    NSDictionary *plist = nil;
    if (plistData)
        plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:outError];
    
    // Read content folder
    NSURL *contentURL = [url URLByAppendingPathComponent:_contentsFolderName];
    _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:[plist objectForKey:_plistContentsKey] parent:nil fileURL:contentURL originalURL:contentURL];
    
    // Read remotes
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

- (BOOL)writeContents:(id)contents andAttributes:(NSDictionary *)additionalFileAttributes safelyToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation error:(NSError *__autoreleasing *)outError {
    
    ASSERT(url);
    // Create project plist
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
    
    // Create the contents folder if it doesn't exist
    if (!_contentsFolder) {
        NSURL *contentsURL = [self.fileURL URLByAppendingPathComponent:_contentsFolderName];
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:nil parent:nil fileURL:contentsURL originalURL:contentsURL];
        ASSERT(_contentsFolder);
    }
    
    // Get content plist
    NSDictionary *contentsPlist = _contentsFolder.propertyListDictionary;
    if (contentsPlist) {
        [plist setObject:contentsPlist forKey:_plistContentsKey];
    }
    
    // Get remotes
    if ([self.remotes count]) {
        NSMutableArray *remotesPlist = [NSMutableArray arrayWithCapacity:[self.remotes count]];
        for (ACProjectFileBookmark *remote in self.remotes) {
            [remotesPlist addObject:[remote propertyListDictionary]];
        }
        [plist setObject:remotesPlist forKey:_plistRemotesKey];
    }
    
    // Write the document bundle if needed, ignore it if it fails
    [[[NSFileManager alloc] init] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Apply attributes to document bundle
    if (![url setResourceValues:additionalFileAttributes error:outError]) {
        return NO;
    };
    
    // Write plist
    NSURL *plistURL = [url URLByAppendingPathComponent:_projectPlistFileName];
    if (![[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:outError] writeToURL:plistURL atomically:YES]) {
        return NO;
    }
    
    // If we're being saved to a new URL, we need to force a write of all contents
    if (_contentsFolder && saveOperation == UIDocumentSaveForCreating) {
        NSURL *contentsURL = [url URLByAppendingPathComponent:_contentsFolderName];
        if (![_contentsFolder writeToURL:contentsURL]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
    _lastError = error;
#if DEBUG
    NSLog(@">>>>>>>>>>>>>>>>> %@", error);
#endif
}

#pragma mark - Projects list

+ (NSArray *)projects {
    NSMutableArray *projects = [[NSMutableArray alloc] init];
    for (NSString *uuid in _projectsList.allKeys) {
        [projects addObject:[[self alloc] _initWithUUID:uuid]];
    }
    return projects;
}

+ (ACProject *)projectWithUUID:(id)uuid {
    NSDictionary *projectInfo = [_projectsList objectForKey:uuid];
    if (!projectInfo) {
        return nil;
    }
    return [[self alloc] _initWithUUID:uuid];
}

+ (void)createProjectWithName:(NSString *)name importArchiveURL:(NSURL *)archiveURL completionHandler:(void (^)(ACProject *, NSError *))completionHandler {
    ASSERT(completionHandler); // The returned project is open and it must be closed by caller
    NSString *uuid = [[NSString alloc] initWithGeneratedUUIDNotContainedInSet:_projectUUIDs];
    ACProject *project = [[self alloc] _initWithUUID:uuid];
    [project saveToURL:project.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (success) {
            ASSERT(project->_lastError == nil);
            // Post the creation of a new project to the notification center
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:_projectsList.count] forKey:ACProjectNotificationIndexKey];
            [notificationCenter postNotificationName:ACProjectWillInsertProjectNotificationName object:self userInfo:userInfo];
            [_projectsList setObject:[NSDictionary dictionaryWithObjectsAndKeys:name, _plistNameKey, nil] forKey:uuid];
            [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
            [notificationCenter postNotificationName:ACProjectDidInsertProjectNotificationName object:self userInfo:userInfo];
            
            completionHandler(project, nil);
        } else {
            ASSERT(project->_lastError);
            completionHandler(nil, project->_lastError);
        }
    }];
}

#pragma mark - Project metadata

- (id)UUID {
    return self.fileURL.lastPathComponent;
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
    ASSERT(_contentsFolder || self.documentState & UIDocumentStateClosed);
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

#pragma mark - Project-wide operations

- (void)remove {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:[_projectsList.allKeys indexOfObject:self.UUID]] forKey:ACProjectNotificationIndexKey];
    [notificationCenter postNotificationName:ACProjectWillRemoveProjectNotificationName object:[self class] userInfo:userInfo];
    [_projectsList removeObjectForKey:self.UUID];
    [notificationCenter postNotificationName:ACProjectDidRemoveProjectNotificationName object:[self class] userInfo:userInfo];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[[NSFileCoordinator alloc] init] coordinateWritingItemAtURL:self.fileURL options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
            [[[NSFileManager alloc] init] removeItemAtURL:newURL error:NULL];
        }];
    });
}

#pragma mark - Internal Remotes Methods

- (void)didRemoveRemote:(ACProjectRemote *)remote {
    ASSERT(remote);
    [self willChangeValueForKey:@"remotes"];
    [_remotes removeObjectForKey:remote.UUID];
    [self didChangeValueForKey:@"remotes"];
}

#pragma mark - Internal Bookmarks Methods

- (void)didAddBookmark:(ACProjectFileBookmark *)bookmark {
    ASSERT(bookmark);
    [self willChangeValueForKey:@"bookmarks"];
    [_bookmarksCache setObject:bookmark forKey:bookmark.UUID];
    [self didChangeValueForKey:@"bookmarks"];
}

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark {
    ASSERT(bookmark);
    [self willChangeValueForKey:@"bookmarks"];
    [_bookmarksCache removeObjectForKey:bookmark.UUID];
    [self didChangeValueForKey:@"bookmarks"];
}

#pragma mark - Internal Files Methods

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem {
    // Called when adding a file and in loading phase
    ASSERT(fileSystemItem);
    [self willChangeValueForKey:@"files"];
    [_filesCache setObject:fileSystemItem forKey:fileSystemItem.UUID];
    [self didChangeValueForKey:@"files"];
}

- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem {
    ASSERT(fileSystemItem);
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

+ (NSString *)_nameForProject:(ACProject *)project {
    ASSERT(project && [_projectsList objectForKey:project.UUID]);
    return [(NSDictionary *)[_projectsList objectForKey:project.UUID] objectForKey:_plistNameKey];
}

+ (void)_setName:(NSString *)name forProject:(ACProject *)project {
    ASSERT(name && project && [_projectsList objectForKey:project.UUID]);
    [project willChangeValueForKey:@"name"];
    NSMutableDictionary *projectInfo = [[_projectsList objectForKey:project.UUID] mutableCopy];;
    [projectInfo setObject:name forKey:_plistNameKey];
    [_projectsList setObject:projectInfo forKey:project.UUID];
    [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
    [project didChangeValueForKey:@"name"];
}

+ (UIColor *)_labelColorForProject:(ACProject *)project {
    ASSERT(project && [_projectsList objectForKey:project.UUID]);
    NSString *hexString = [(NSDictionary *)[_projectsList objectForKey:project.UUID] objectForKey:_plistLabelColorKey];
    UIColor *labelColor = nil;
    if ([hexString length]) {
        labelColor = [UIColor colorWithHexString:hexString];
    }
    return labelColor;
}

+ (void)_setLabelColor:(UIColor *)color forProject:(ACProject *)project {
    ASSERT(color && project && [_projectsList objectForKey:project.UUID]);
    [project willChangeValueForKey:@"labelColor"];
    NSMutableDictionary *projectInfo = [[_projectsList objectForKey:project.UUID] mutableCopy];
    [projectInfo setObject:color.hexString forKey:_plistLabelColorKey];
    [_projectsList setObject:projectInfo forKey:project.UUID];
    [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
    [project didChangeValueForKey:@"labelColor"];
}

- (id)_initWithUUID:(NSString *)uuid {
    self = [super initWithFileURL:[[[self class] _projectsDirectory] URLByAppendingPathComponent:uuid]];
    if (!self) {
        return nil;
    }
    _filesCache = [NSMutableDictionary new];
    _bookmarksCache = [NSMutableDictionary new];
    _remotes = [NSMutableDictionary new];
    return self;
}

#if DEBUG

+ (void)_removeAllProjects {
    NSURL *projectsDirectory = [self _projectsDirectory];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *project in [fileManager contentsOfDirectoryAtURL:projectsDirectory includingPropertiesForKeys:nil options:0 error:NULL]) {
        [fileManager removeItemAtURL:project error:NULL];
    }
    _projectsList = [[NSMutableDictionary alloc] init];
    _projectUUIDs = [[NSMutableSet alloc] init];
}

#endif

@end
