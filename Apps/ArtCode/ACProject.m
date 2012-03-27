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
#import "NSString+Utilities.h"

#import "ArtCodeURL.h"
#import "ArchiveUtilities.h"

NSString * const ACProjectWillInsertProjectNotificationName = @"ACProjectWillInsertProjectNotificationName";
NSString * const ACProjectDidInsertProjectNotificationName = @"ACProjectDidInsertProjectNotificationName";
NSString * const ACProjectWillRemoveProjectNotificationName = @"ACProjectWillRemoveProjectNotificationName";
NSString * const ACProjectDidRemoveProjectNotificationName = @"ACProjectDidRemoveProjectNotificationName";
NSString * const ACProjectNotificationIndexKey = @"ACProjectNotificationIndexKey";

static NSMutableSet *_projectUUIDs;

/// UUID to dictionary of cached projects informations (uuid, path, labelColor, name).
static NSMutableDictionary *_projectsList = nil;
/// An array of ACProject instances that cannot be opened but can serve as reference for opened projects. 
/// Used in projects, [ACProject createProjectWithName:importArchiveURL:completionHandler:].
static NSMutableArray *_projectsSortedList = nil;

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _contentsFolderName = @"Contents";

// Metadata
static NSString * const _projectsListKey = @"ACProjectProjectsList";
static NSString * const _plistNameKey = @"name";
static NSString * const _plistLabelColorKey = @"labelColor";
static NSString * const _plistIsNewlyCreatedKey = @"newlyCreated";

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

@property (nonatomic, readwrite, getter = isNewlyCreated) BOOL newlyCreated;

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
    for (NSURL *projectURL in [fileManager contentsOfDirectoryAtURL:[self _projectsDirectory] includingPropertiesForKeys:nil options:0 error:NULL]) {
        NSString *uuid = projectURL.lastPathComponent;
        NSDictionary *projectInfo = [_projectsList objectForKey:uuid];
        if (projectInfo) {
            [newProjectsList setObject:projectInfo forKey:uuid];
        } else {
            [fileManager removeItemAtURL:projectURL error:NULL];
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

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler {
    [super openWithCompletionHandler:^(BOOL success) {
        if (success)
            [[self class] removeMetaForProject:self key:_plistIsNewlyCreatedKey];
        if (completionHandler)
            completionHandler(success);
    }];
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
    _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:[plist objectForKey:_plistContentsKey] parent:nil fileURL:contentURL];
    
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
        _contentsFolder = [[ACProjectFolder alloc] initWithProject:self propertyListDictionary:nil parent:nil fileURL:contentsURL];
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
    if (additionalFileAttributes && ![url setResourceValues:additionalFileAttributes error:outError]) {
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
        if (![_contentsFolder writeToURL:contentsURL error:outError]) {
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
    if (!_projectsSortedList) {
        _projectsSortedList = [NSMutableArray new];
        [_projectsList enumerateKeysAndObjectsUsingBlock:^(NSString *uuidKey, id obj, BOOL *stop) {
            [_projectsSortedList addObject:[[self alloc] _initWithUUID:uuidKey]];
        }];
        [_projectsSortedList sortUsingComparator:^NSComparisonResult(ACProject *obj1, ACProject *obj2) {
            return [obj1.name compare:obj2.name];
        }];
    }
    return [_projectsSortedList copy];
}

+ (ACProject *)projectWithUUID:(id)uuid {
    NSDictionary *projectInfo = [_projectsList objectForKey:uuid];
    if (!projectInfo) {
        return nil;
    }
    return [[self alloc] _initWithUUID:uuid];
}

+ (void)createProjectWithName:(NSString *)name labelColor:(UIColor *)labelColor importArchiveURL:(NSURL *)archiveURL completionHandler:(void (^)(ACProject *, NSError *))completionHandler {
    ASSERT(completionHandler); // The returned project is open and it must be closed by caller
    NSString *uuid = [[NSString alloc] initWithGeneratedUUIDNotContainedInSet:_projectUUIDs];
    ACProject *project = [[self alloc] _initWithUUID:uuid];
    [project saveToURL:project.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (success) {
            ASSERT(project->_lastError == nil);
            // Retrieve the index in which the new project will be added in the sorted project's array
            __block NSUInteger insertionIndex = 0;
            [[self projects] enumerateObjectsUsingBlock:^(ACProject *p, NSUInteger idx, BOOL *stop) {
                if ([p.name compare:name] == NSOrderedAscending) {
                    insertionIndex = idx + 1;
                } else {
                    *stop = YES;
                }
            }];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:insertionIndex] forKey:ACProjectNotificationIndexKey];
            
            // Notify start of operations via notification center
            [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectWillInsertProjectNotificationName object:self userInfo:userInfo];
            
            void (^insertProjectAndNotify)(void) = ^{
                // Insert the project
                if (labelColor)
                    [_projectsList setObject:[NSDictionary dictionaryWithObjectsAndKeys:name, _plistNameKey, [NSNumber numberWithBool:YES], _plistIsNewlyCreatedKey, labelColor.hexString, _plistLabelColorKey, nil] forKey:uuid];
                else
                    [_projectsList setObject:[NSDictionary dictionaryWithObjectsAndKeys:name, _plistNameKey, [NSNumber numberWithBool:YES], _plistIsNewlyCreatedKey, nil] forKey:uuid];
                ASSERT(_projectsSortedList);
                [_projectsSortedList insertObject:[[self alloc] _initWithUUID:uuid] atIndex:insertionIndex];
                [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
                
                // Notify finish
                [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectDidInsertProjectNotificationName object:self userInfo:userInfo];
            };
            
            // Extract files if needed
            NSFileManager *fileManager = [NSFileManager new];
            if (archiveURL && [fileManager fileExistsAtPath:archiveURL.path]) {
                NSError *err = nil;
                NSURL *tempURL = [NSURL temporaryDirectory];
                if (![fileManager createDirectoryAtURL:tempURL withIntermediateDirectories:YES attributes:nil error:&err]) {
                    // TODO remove project?
                    completionHandler(nil, err);
                    return;
                }
                // Extract into the temporary directory
                [ArchiveUtilities extractArchiveAtURL:archiveURL toDirectory:tempURL];
                
                // Update project's content with extracted items
                [project.contentsFolder updateWithContentsOfURL:tempURL completionHandler:^(NSError *error) {
                    [fileManager removeItemAtURL:tempURL error:&error];
                    insertProjectAndNotify();
                    completionHandler(project, project->_lastError ? project->_lastError : error);
                }];
                return;
            }
            
            // If no content's to extract, just insert the project and notify
            insertProjectAndNotify();
            completionHandler(project, nil);
        } else {
            ASSERT(project->_lastError);
            completionHandler(nil, project->_lastError);
        }
    }];
}

+ (id)metaForProject:(ACProject *)project key:(NSString *)key {
    ASSERT(project && [_projectsList objectForKey:project.UUID]);
    return [(NSDictionary *)[_projectsList objectForKey:project.UUID] objectForKey:key];
}

+ (void)setMeta:(id)info forProject:(ACProject *)project key:(NSString *)key {
    ASSERT([info isKindOfClass:[NSString class]] || [info isKindOfClass:[NSArray class]] || [info isKindOfClass:[NSDictionary class]] || [info isKindOfClass:[NSNumber class]]);
    ASSERT(project && [_projectsList objectForKey:project.UUID]);
    NSMutableDictionary *projectInfo = [[_projectsList objectForKey:project.UUID] mutableCopy];
    [projectInfo setObject:info forKey:key];
    [_projectsList setObject:projectInfo forKey:project.UUID];
    [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
}

+ (void)removeMetaForProject:(ACProject *)project key:(NSString *)key {
    ASSERT(project && [_projectsList objectForKey:project.UUID]);
    NSMutableDictionary *projectInfo = [[_projectsList objectForKey:project.UUID] mutableCopy];
    [projectInfo removeObjectForKey:key];
    [_projectsList setObject:projectInfo forKey:project.UUID];
    [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
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

- (BOOL)isNewlyCreated {
    return [[[self class] metaForProject:self key:_plistIsNewlyCreatedKey] boolValue];
}

- (void)setNewlyCreated:(BOOL)newlyCreated {
    [self willChangeValueForKey:@"newlyCreated"];
    [[self class] setMeta:[NSNumber numberWithBool:newlyCreated] forProject:self key:_plistIsNewlyCreatedKey];
    [self didChangeValueForKey:@"newlyCreated"];
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

- (void)duplicateWithCompletionHandler:(void (^)(ACProject *, NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [self performAsynchronousFileAccessUsingBlock:^{
        NSError *error = nil;
        
        // Save the project
        if (![self writeContents:nil andAttributes:nil safelyToURL:self.fileURL forSaveOperation:UIDocumentSaveForOverwriting error:&error]) {
            ASSERT(error);
            if (completionHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionHandler(nil, error);
                }];
            }
        }
        
        // Copy files to duplicate project
        NSString *duplicateUUID = [[NSString alloc] initWithGeneratedUUIDNotContainedInSet:_projectUUIDs];
        if (![[[NSFileManager alloc] init] copyItemAtURL:self.fileURL toURL:[self.class._projectsDirectory URLByAppendingPathComponent:duplicateUUID] error:&error]) {
            ASSERT(error);
            
            if (completionHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionHandler(nil, error);
                }];
            }
        }
        
        // Add duplicate project to projects list
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSMutableDictionary *projectInfo = [[_projectsList objectForKey:self.UUID] mutableCopy];
            NSString *name = [projectInfo objectForKey:_plistNameKey];
            NSString *duplicateName = nil;
            for (NSUInteger number = 1;;++number) {
                duplicateName = [name stringByAddingDuplicateNumber:number];
                __block BOOL isUnique = YES;
                [_projectsList enumerateKeysAndObjectsUsingBlock:^(NSString *uuid, NSDictionary *info, BOOL *stop) {
                    if (![duplicateName isEqualToString:[info objectForKey:_plistNameKey]]) {
                        return;
                    }
                    isUnique = NO;
                    *stop = YES;
                }];
                if (isUnique) {
                    break;
                }
            }
            [projectInfo setObject:duplicateName forKey:_plistNameKey];
            [projectInfo setObject:[NSNumber numberWithBool:YES] forKey:_plistIsNewlyCreatedKey];
            [_projectsList setObject:projectInfo forKey:duplicateUUID];
            if (completionHandler) {
                completionHandler([self.class.alloc _initWithUUID:duplicateUUID], nil);
            }
        }];
    }];
}

- (void)remove {
    NSString *removeUUID = self.UUID;
    __block NSUInteger removeIndex = NSNotFound;
    [[[self class] projects] enumerateObjectsUsingBlock:^(ACProject *p, NSUInteger idx, BOOL *stop) {
        if ([p.UUID isEqualToString:removeUUID]) {
            removeIndex = idx;
            *stop = YES;
        }
    }];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:removeIndex] forKey:ACProjectNotificationIndexKey]; 
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectWillRemoveProjectNotificationName object:[self class] userInfo:userInfo];
    [_projectsList removeObjectForKey:removeUUID];
    ASSERT(_projectsSortedList);
    [_projectsSortedList removeObjectAtIndex:removeIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectDidRemoveProjectNotificationName object:[self class] userInfo:userInfo];
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
    return [self metaForProject:project key:_plistNameKey];
}

+ (void)_setName:(NSString *)name forProject:(ACProject *)project {
    [project willChangeValueForKey:@"name"];
    [self setMeta:name forProject:project key:_plistNameKey];
    [project didChangeValueForKey:@"name"];
}

+ (UIColor *)_labelColorForProject:(ACProject *)project {
    NSString *hexString = [self metaForProject:project key:_plistLabelColorKey];
    UIColor *labelColor = nil;
    if ([hexString length]) {
        labelColor = [UIColor colorWithHexString:hexString];
    }
    return labelColor;
}

+ (void)_setLabelColor:(UIColor *)color forProject:(ACProject *)project {
    [project willChangeValueForKey:@"labelColor"];
    [self setMeta:color.hexString forProject:project key:_plistLabelColorKey];
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
    _projectsSortedList = nil;
    _projectUUIDs = [[NSMutableSet alloc] init];
}

#endif

@end
