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

#import "DocumentWrapper.h"

#import "ArtCodeURL.h"

#import <objc/runtime.h>


NSString * const ACProjectWillAddProjectNotificationName = @"ACProjectWillAddProjectNotificationName";
NSString * const ACProjectDidAddProjectNotificationName = @"ACProjectDidAddProjectNotificationName";
NSString * const ACProjectWillRemoveProjectNotificationName = @"ACProjectWillRemoveProjectNotificationName";
NSString * const ACProjectDidRemoveProjectNotificationName = @"ACProjectDidRemoveProjectNotificationName";
NSString * const ACProjectNotificationProjectKey = @"ACProjectNotificationProjectKey";

NSString * const ACProjectWillAddItem = @"ACProjectWillAddItem";
NSString * const ACProjectDidAddItem = @"ACProjectDidAddItem";
NSString * const ACProjectWillRemoveItem = @"ACProjectWillRemoveItem";
NSString * const ACProjectDidRemoveItem = @"ACProjectDidRemoveItem";
NSString * const ACProjectNotificationItemKey = @"ACProjectNotificationItemKey";

static NSMutableSet *_projectUUIDs;

/// UUID to dictionary of cached projects informations (uuid, path, labelColor, name).
static NSMutableDictionary *_projectsList = nil;

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _contentsFolderName = @"Contents";

// Metadata
static NSString * const _projectsListKey = @"ACProjectProjectsList";
static NSString * const _plistNameKey = @"name";
static NSString * const _plistLabelColorKey = @"labelColor";
static NSString * const _plistIsNewlyCreatedKey = @"newlyCreated";

// Content
static NSString * const _plistFilename = @".acproj";
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

@property (nonatomic, strong) ACProjectFolder *contentsFolder;
@property (nonatomic, copy) NSArray *remotes;

@end

#pragma mark

@interface ACProjectDocument : UIDocument

- (id)initWithFileURL:(NSURL *)url project:(ACProject *)project;

@end

#pragma mark

/// Remotes internal inialization for creation
@interface ACProjectRemote (Internal)

- (id)initWithProject:(ACProject *)project name:(NSString *)name URL:(NSURL *)remoteURL;

@end

#pragma mark

@implementation ACProject {
  NSURL *_fileURL;
  ACProjectDocument *_document;
  NSMutableDictionary *_filesCache;
  NSMutableDictionary *_bookmarksCache;
  NSMutableDictionary *_remotes;
}

@synthesize UUID = _UUID, artCodeURL = _artCodeURL, contentsFolder = _contentsFolder;

#pragma mark - Forwarding

+ (BOOL)resolveClassMethod:(SEL)sel
{
  Method method = class_getClassMethod([UIDocument class], sel);
  if (!method)
    return NO;
  Class metaClass = objc_getMetaClass("ACProject");
  class_addMethod(metaClass, sel, method_getImplementation(method), method_getTypeEncoding(method));
  return YES;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  return _document;
}

#pragma mark - NSObject

+ (void)load {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // Docs advise not to call this method, I say docs can shut up (and will probably be proved wrong eventually)
  class_setSuperclass([ACProject class], [NSObject class]);
#pragma clang diagnostic pop
}

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

- (NSURL *)fileURL {
  if (!_fileURL) {
    _fileURL = [self.class._projectsDirectory URLByAppendingPathComponent:_UUID];
  }
  return _fileURL;
}

- (UIDocumentState)documentState {
  if (!_document) {
    return UIDocumentStateClosed;
  }
  return _document.documentState;
}

#pragma mark - Projects list

+ (NSArray *)projects {
  // TODO cache this result
  NSMutableArray *projects = NSMutableArray.alloc.init;
  for (id uuid in _projectsList) {
    [projects addObject:[self.class.alloc _initWithUUID:uuid]];
  }
  return projects;
}

+ (ACProject *)projectWithUUID:(id)uuid {
  NSDictionary *projectInfo = [_projectsList objectForKey:uuid];
  if (!projectInfo) {
    return nil;
  }
  return [self.alloc _initWithUUID:uuid];
}

+ (void)removeProjectWithUUID:(id)uuid {
  __block NSUInteger removeIndex = NSNotFound;
  __block ACProject *project = nil;
  [self.class.projects enumerateObjectsUsingBlock:^(ACProject *p, NSUInteger idx, BOOL *stop) {
    if ([p.UUID isEqualToString:uuid]) {
      removeIndex = idx;
      project = p;
      *stop = YES;
    }
  }];
  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:project forKey:ACProjectNotificationProjectKey];

  [NSNotificationCenter.defaultCenter postNotificationName:ACProjectWillRemoveProjectNotificationName object:self.class userInfo:userInfo];
  [_projectsList removeObjectForKey:uuid];
  [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectDidRemoveProjectNotificationName object:self.class userInfo:userInfo];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [NSFileCoordinator.alloc.init coordinateWritingItemAtURL:project.fileURL options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
      [NSFileManager.alloc.init removeItemAtURL:newURL error:NULL];
    }];
  });
}

+ (void)createProjectWithName:(NSString *)name labelColor:(UIColor *)labelColor completionHandler:(void (^)(ACProject *))completionHandler {
  ASSERT(completionHandler); // The returned project is open and it must be closed by caller
  NSString *uuid = [[NSString alloc] initWithGeneratedUUIDNotContainedInSet:_projectUUIDs];
  [_projectUUIDs addObject:uuid];
  ACProject *project = [[self alloc] _initWithUUID:uuid];
  [project saveToURL:project.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
    if (success) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:project forKey:ACProjectNotificationProjectKey];
      
      // Notify start of operations via notification center
      [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectWillAddProjectNotificationName object:self userInfo:userInfo];
      
      // Insert the project
      if (labelColor)
        [_projectsList setObject:[NSDictionary dictionaryWithObjectsAndKeys:name, _plistNameKey, [NSNumber numberWithBool:YES], _plistIsNewlyCreatedKey, labelColor.hexString, _plistLabelColorKey, nil] forKey:uuid];
      else
        [_projectsList setObject:[NSDictionary dictionaryWithObjectsAndKeys:name, _plistNameKey, [NSNumber numberWithBool:YES], _plistIsNewlyCreatedKey, nil] forKey:uuid];

      [[NSUserDefaults standardUserDefaults] setObject:_projectsList forKey:_projectsListKey];
      
      // Notify finish
      [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectDidAddProjectNotificationName object:self userInfo:userInfo];
      completionHandler(project);
    } else {
      completionHandler(nil);
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

- (NSArray *)files {
  return [_filesCache allValues];
}

- (NSArray *)bookmarks {
  return [_bookmarksCache allValues];
}

- (NSArray *)remotes {
  return [_remotes allValues];
}

- (void)setRemotes:(NSArray *)remotes {
  [_remotes removeAllObjects];
  for (ACProjectRemote *remote in remotes) {
    [_remotes setObject:remote forKey:remote.UUID];
  }
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
  NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
  [self willChangeValueForKey:@"remotes"];
  [defaultCenter postNotificationName:ACProjectWillAddItem object:self userInfo:[NSDictionary dictionaryWithObject:remote forKey:ACProjectNotificationItemKey]];
  [_remotes setObject:remote forKey:remote.UUID];
  [self updateChangeCount:UIDocumentChangeDone];
  [defaultCenter postNotificationName:ACProjectDidAddItem object:self userInfo:[NSDictionary dictionaryWithObject:remote forKey:ACProjectNotificationItemKey]];
  [self didChangeValueForKey:@"remotes"];
  return remote;
}

- (void)removeRemote:(ACProjectRemote *)remote {
  NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
  [self willChangeValueForKey:@"remotes"];
  [defaultCenter postNotificationName:ACProjectWillRemoveItem object:self userInfo:[NSDictionary dictionaryWithObject:remote forKey:ACProjectNotificationItemKey]];
  [remote prepareForRemoval];
  [_remotes removeObjectForKey:remote.UUID];
  [self updateChangeCount:UIDocumentChangeDone];
  [defaultCenter postNotificationName:ACProjectDidRemoveItem object:self userInfo:[NSDictionary dictionaryWithObject:remote forKey:ACProjectNotificationItemKey]];
  [self didChangeValueForKey:@"remotes"];
}

#pragma mark - Project-wide operations

- (void)duplicateWithCompletionHandler:(void (^)(ACProject *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  completionHandler = [completionHandler copy];
  NSString *duplicateUUID = [[NSString alloc] initWithGeneratedUUIDNotContainedInSet:_projectUUIDs];
  [_projectUUIDs addObject:duplicateUUID];
  NSURL *duplicateURL = [self.class._projectsDirectory URLByAppendingPathComponent:duplicateUUID];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSFileCoordinator *fileCoordinator = NSFileCoordinator.alloc.init;
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:0 writingItemAtURL:duplicateURL options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
      [NSFileManager.alloc.init copyItemAtURL:newReadingURL toURL:newWritingURL error:NULL];
    }];
    
    // Add duplicate project to projects list
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
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
        completionHandler([self.class.alloc _initWithUUID:duplicateUUID]);
      }
    }];
  });
}

#pragma mark - Internal Bookmarks Methods

- (void)addBookmark:(ACProjectFileBookmark *)bookmark withBlock:(void(^)(void))block {
  ASSERT(bookmark);
  NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
  [self willChangeValueForKey:@"bookmarks"];
  [defaultCenter postNotificationName:ACProjectWillAddItem object:self userInfo:[NSDictionary dictionaryWithObject:bookmark forKey:ACProjectNotificationItemKey]];
  block();
  [_bookmarksCache setObject:bookmark forKey:bookmark.UUID];
  [defaultCenter postNotificationName:ACProjectDidAddItem object:self userInfo:[NSDictionary dictionaryWithObject:bookmark forKey:ACProjectNotificationItemKey]];
  [self didChangeValueForKey:@"bookmarks"];
}

- (void)removeBookmark:(ACProjectFileBookmark *)bookmark withBlock:(void(^)(void))block {
  ASSERT(bookmark);
  NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
  [self willChangeValueForKey:@"bookmarks"];
  [defaultCenter postNotificationName:ACProjectWillRemoveItem object:self userInfo:[NSDictionary dictionaryWithObject:bookmark forKey:ACProjectNotificationItemKey]];
  [_bookmarksCache removeObjectForKey:bookmark.UUID];
  block();
  [defaultCenter postNotificationName:ACProjectDidRemoveItem object:self userInfo:[NSDictionary dictionaryWithObject:bookmark forKey:ACProjectNotificationItemKey]];
  [self didChangeValueForKey:@"bookmarks"];
}

#pragma mark - Internal Files Methods

- (void)addFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem withBlock:(void(^)(void))block {
  // Called when adding a file and in loading phase
  ASSERT(fileSystemItem);
  NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
  [self willChangeValueForKey:@"files"];
  [defaultCenter postNotificationName:ACProjectWillAddItem object:self userInfo:[NSDictionary dictionaryWithObject:fileSystemItem forKey:ACProjectNotificationItemKey]];
  block();
  [_filesCache setObject:fileSystemItem forKey:fileSystemItem.UUID];
  [defaultCenter postNotificationName:ACProjectDidAddItem object:self userInfo:[NSDictionary dictionaryWithObject:fileSystemItem forKey:ACProjectNotificationItemKey]];
  [self didChangeValueForKey:@"files"];
}

- (void)removeFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem withBlock:(void(^)(void))block {
  ASSERT(fileSystemItem);
  NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
  [self willChangeValueForKey:@"files"];
  [defaultCenter postNotificationName:ACProjectWillRemoveItem object:self userInfo:[NSDictionary dictionaryWithObject:fileSystemItem forKey:ACProjectNotificationItemKey]];
  [_filesCache removeObjectForKey:fileSystemItem.UUID];
  block();
  [defaultCenter postNotificationName:ACProjectDidRemoveItem object:self userInfo:[NSDictionary dictionaryWithObject:fileSystemItem forKey:ACProjectNotificationItemKey]];
  [self didChangeValueForKey:@"files"];
}

#pragma mark - Private Methods

+ (NSURL *)_projectsDirectory {
  static NSURL *_projectsDirectory = nil;
  if (!_projectsDirectory) {
    _projectsDirectory = [NSURL.applicationLibraryDirectory URLByAppendingPathComponent:_projectsFolderName isDirectory:YES];
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
  if (hexString.length) {
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
  self = [super init];
  if (!self) {
    return nil;
  }
  _UUID = uuid;
  _filesCache = NSMutableDictionary.alloc.init;
  _bookmarksCache = NSMutableDictionary.alloc.init;
  _remotes = NSMutableDictionary.alloc.init;
  __weak ACProject *weakSelf = self;
  _document = [DocumentWrapper wrapperWithBlock:^UIDocument *{
    ACProject *strongSelf = weakSelf;
    if (!strongSelf) {
      return nil;
    }
    return [ACProjectDocument.alloc initWithFileURL:strongSelf.fileURL project:strongSelf];
  }];
  return self;
}

#if DEBUG

+ (void)_removeAllProjects {
  NSURL *projectsDirectory = self._projectsDirectory;
  NSFileManager *fileManager = NSFileManager.alloc.init;
  for (NSURL *project in [fileManager contentsOfDirectoryAtURL:projectsDirectory includingPropertiesForKeys:nil options:0 error:NULL]) {
    [fileManager removeItemAtURL:project error:NULL];
  }
  _projectsList = NSMutableDictionary.alloc.init;
  _projectUUIDs = NSMutableSet.alloc.init;
}

#endif

@end

#pragma mark

@implementation ACProject (RACExtensions)

+ (RACSubscribable *)rac_projects {
  static RACSubscribable *_rac_projects = nil;
  if (!_rac_projects) {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    _rac_projects = [RACSubscribable merge:[NSArray arrayWithObjects:[notificationCenter rac_addObserverForName:ACProjectDidAddProjectNotificationName object:self], [notificationCenter rac_addObserverForName:ACProjectDidRemoveProjectNotificationName object:self], nil]];
  }
  return _rac_projects;
}

@end

#pragma mark

@implementation ACProjectDocument {
  __weak ACProject *_project;
  BOOL _isDirty;
}

#pragma mark - UIDocument

- (id)initWithFileURL:(NSURL *)url {
  UNIMPLEMENTED(); // Designated initializer is -initWithFileURL:project:
}

- (NSString *)localizedName {
  UNIMPLEMENTED(); // Use name instead
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

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [super openWithCompletionHandler:^(BOOL success) {
    if (success) {
      [ACProject removeMetaForProject:_project key:_plistIsNewlyCreatedKey];
    }
    if (completionHandler) {
      completionHandler(success);
    }
  }];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  ASSERT(_project);
  
  if (![contents isKindOfClass:[NSFileWrapper class]]) {
    return NO;
  }
  NSFileWrapper *fileWrapper = (NSFileWrapper *)contents;
  
  // Read plist
  NSData *plistData = [[fileWrapper.fileWrappers objectForKey:_plistFilename] regularFileContents];
  NSDictionary *plist = nil;
  if (plistData)
    plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:NULL];
  
  // Read content folder
  _project.contentsFolder = [ACProjectFolder.alloc initWithProject:_project fileWrapper:[fileWrapper.fileWrappers objectForKey:_contentsFolderName] propertyListDictionary:[plist objectForKey:_plistContentsKey]];
  
  ASSERT(_project.contentsFolder);
  
  // Read remotes
  if ([plist objectForKey:_plistRemotesKey]) {
    NSMutableDictionary *remotesFromPlist = NSMutableDictionary.alloc.init;
    for (NSDictionary *remotePlist in [plist objectForKey:_plistRemotesKey]) {
      ACProjectRemote *remote = [ACProjectRemote.alloc initWithProject:_project propertyListDictionary:remotePlist];
      if (remote) {
        [remotesFromPlist setObject:remote forKey:remote.UUID];
      }
    }
    _project.remotes = remotesFromPlist.copy;
  }
  return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  ASSERT(_project);  
  
  // Create project plist and fileWrapper
  NSMutableDictionary *plist = NSMutableDictionary.alloc.init;
  NSFileWrapper *fileWrapper = [NSFileWrapper.alloc initDirectoryWithFileWrappers:nil];
  
  // Get contents
  if (!_project.contentsFolder) {
    NSFileWrapper *contentsFileWrapper = [NSFileWrapper.alloc initDirectoryWithFileWrappers:nil];
    contentsFileWrapper.preferredFilename = _contentsFolderName;
    _project.contentsFolder = [ACProjectFolder.alloc initWithProject:_project fileWrapper:contentsFileWrapper propertyListDictionary:nil];
  }
  NSDictionary *contentsPlist = _project.contentsFolder.propertyListDictionary;
  if (contentsPlist) {
    [plist setObject:contentsPlist forKey:_plistContentsKey];
  }
  NSFileWrapper *contentsFileWrapper = _project.contentsFolder.fileWrapper;
  if (contentsFileWrapper) {
    [fileWrapper addFileWrapper:contentsFileWrapper];
  }
  
  // Get remotes
  if (_project.remotes.count) {
    NSMutableArray *remotesPlist = [NSMutableArray arrayWithCapacity:_project.remotes.count];
    for (ACProjectFileBookmark *remote in _project.remotes) {
      [remotesPlist addObject:remote.propertyListDictionary];
    }
    [plist setObject:remotesPlist forKey:_plistRemotesKey];
  }
  
  // Serialize property list
  NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
  if (plistData) {
    NSFileWrapper *plistFileWrapper = [NSFileWrapper.alloc initRegularFileWithContents:plistData];
    plistFileWrapper.preferredFilename = _plistFilename;
    if (plistFileWrapper) {
      [fileWrapper addFileWrapper:plistFileWrapper];
    }
  }
  
  return fileWrapper;
}

#if DEBUG
- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {
  NSLog(@">>>>>>>>>>>>>>>>> %@", error);
}
#endif

#pragma mark - Public Methods

- (id)initWithFileURL:(NSURL *)url project:(ACProject *)project {
  ASSERT(project);
  self = [super initWithFileURL:url];
  if (!self)
    return nil;
  _project = project;
  return self;
}

@end
