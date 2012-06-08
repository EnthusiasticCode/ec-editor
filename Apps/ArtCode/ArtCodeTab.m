//
//  Tab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTab.h"
#import "ArtCodeURL.h"
#import "ACProject.h"
#import "ACProjectItem.h"
#import "ACProjectFileBookmark.h"

#import "DocSet.h"
#import "DocSetDownloadManager.h"

#import "NSURL+Utilities.h"
#import <objc/runtime.h>

static NSString * const _plistFileName = @"Tabs.plist";
static NSString * const _historyURLsKey = @"HistoryURLs";
static NSString * const _currentHistoryPositionKey = @"currentHistoryPosition";

static NSURL *_plistURL;
static NSMutableArray *_mutableTabDictionaries;
static NSMutableArray *_mutableTabs;

@interface ArtCodeTab ()

@property (nonatomic, getter = isLoading) BOOL loading;
@property (nonatomic, strong) ACProject *currentProject;
@property (nonatomic, strong) ACProjectItem *currentItem;
@property (nonatomic, strong) DocSet *currentDocSet;

- (id)_initWithDictionary:(NSMutableDictionary *)dictionary;

- (void)_loadFirstValidProjectItem;

/// Moves the current URL for the tab and populate current project and item if neccessary.
- (void)_moveFromURL:(NSURL *)fromURL toURL:(NSURL *)toURL completionHandler:(void(^)(BOOL success))completionHandler;

/// Removes hisotry entries with an URL containing the given UUID and updates properties.
- (void)_removeHistoryEntriesContainingUUID:(id)uuid;

@end

@implementation ArtCodeTab
{
  NSMutableDictionary *_mutableDictionary;
  // This array is maintained in parallel with _mutableDictionary's _historyURLsKey key to have NSURLs instead of strings
  NSMutableArray *_mutableHistoryURLs;
}

@synthesize loading = _loading, currentProject = _currentProject, currentItem = _currentItem, currentDocSet = _currentDocSet;

- (ACProjectItem *)currentItem {
  if (_currentItem)
    return _currentItem;
  if (_currentProject)
    return (ACProjectItem *)_currentProject.contentsFolder;
  return nil;
}

- (ACProjectFile *)currentFile {
  switch (self.currentItem.type) {
    case ACPFile:
      return (ACProjectFile *)self.currentItem;
    case ACPFileBookmark:
      return ((ACProjectFileBookmark *)self.currentItem).file;
    default:
      return nil;
  }
}

- (ACProjectFolder *)currentFolder {
  if (self.currentItem.type == ACPFolder) {
    return (ACProjectFolder *)self.currentItem;
  }
  return nil;
}

+ (NSSet *)keyPathsForValuesAffectingCurrentFile {
  return [NSSet setWithObject:@"currentItem"];
}

+ (NSSet *)keyPathsForValuesAffectingCurrentFolder {
  return [NSSet setWithObject:@"currentItem"];
}

#pragma mark - Class methods

+ (void)initialize
{
  if (self != [ArtCodeTab class])
    return;
  
  // Load persitent history
  _plistURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_plistFileName];
  NSData *plistData = [NSData dataWithContentsOfURL:_plistURL options:NSDataReadingUncached error:NULL];
  if (plistData) {
    _mutableTabDictionaries = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:0 error:NULL];
  }
  if (!_mutableTabDictionaries) {
    _mutableTabDictionaries = [[NSMutableArray alloc] init];
  }
  
  // Create tabs
  _mutableTabs = [[NSMutableArray alloc] init];
  if (![_mutableTabDictionaries count]) {
    [self blankTab]; // no need to do anything with the return value, it will be automatically added to the class arrays
  } else {
    for (NSMutableDictionary *dictionary in _mutableTabDictionaries) {
      [_mutableTabs addObject:[[self alloc] _initWithDictionary:dictionary]];
    }
  }
  
  // React to remove history items from tab's history when a project is eliminated
  [[[NSNotificationCenter defaultCenter] rac_addObserverForName:ACProjectWillRemoveProjectNotificationName object:[ACProject class]] subscribeNext:^(NSNotification *note) {
    ACProject *project = [note.userInfo objectForKey:ACProjectNotificationProjectKey];
    if (!project)
      return;
    
    id projectUUID = project.UUID;
    for (ArtCodeTab *tab in _mutableTabs) {
      [tab _removeHistoryEntriesContainingUUID:projectUUID];
    }
  }];
  
  // Remove history items from tab when item is eliminated
  [[[NSNotificationCenter defaultCenter] rac_addObserverForName:ACProjectWillRemoveItem object:nil] subscribeNext:^(NSNotification *note) {
    ACProjectItem *item = [note.userInfo objectForKey:ACProjectNotificationItemKey];
    if (!item)
      return;
    
    id itemUUID = item.UUID;
    for (ArtCodeTab *tab in _mutableTabs) {
      [tab _removeHistoryEntriesContainingUUID:itemUUID];
    }
  }];
}

+ (NSArray *)allTabs
{
  return [_mutableTabs copy];
}

+ (ArtCodeTab *)blankTab
{
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  [_mutableTabDictionaries addObject:dictionary];
  ArtCodeTab *newTab = [[self alloc] _initWithDictionary:dictionary]; 
  [_mutableTabs addObject:newTab];
  return newTab;
}

+ (ArtCodeTab *)duplicateTab:(ArtCodeTab *)tab
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:0], _currentHistoryPositionKey, [NSMutableArray arrayWithObject:[[tab->_mutableDictionary objectForKey:_historyURLsKey] objectAtIndex:[[tab->_mutableDictionary objectForKey:_currentHistoryPositionKey] unsignedIntegerValue]]], _historyURLsKey, nil];
  [_mutableTabDictionaries addObject:dictionary];
  ArtCodeTab *newTab = [[self alloc] _initWithDictionary:dictionary];
  [_mutableTabs addObject:newTab];
  return newTab;
}

+ (void)removeTab:(ArtCodeTab *)tab
{
  [_mutableTabs removeObject:tab];
  [_mutableTabDictionaries removeObject:tab->_mutableDictionary];
}

+ (void)saveTabsToDisk
{
  NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:_mutableTabDictionaries format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
  [plistData writeToURL:_plistURL atomically:YES];
}

#pragma mark - Properties

- (NSArray *)historyURLs
{
  return [_mutableHistoryURLs copy];
}

- (NSUInteger)currentHistoryPosition
{
  return [[_mutableDictionary objectForKey:_currentHistoryPositionKey] unsignedIntegerValue];
}

- (void)setCurrentHistoryPosition:(NSUInteger)currentHistoryPosition {
  [_mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:currentHistoryPosition] forKey:_currentHistoryPositionKey];
}

- (NSURL *)currentURL
{
  return [_mutableHistoryURLs objectAtIndex:self.currentHistoryPosition];
}

+ (NSSet *)keyPathsForValuesAffectingCurrentURL
{
  return [NSSet setWithObject:@"currentHistoryPosition"];
}

- (BOOL)canMoveBackInHistory
{
  return self.currentHistoryPosition > 0;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveBackInHistory
{
  return [NSSet setWithObject:@"currentHistoryPosition"];
}

- (BOOL)canMoveForwardInHistory
{
  return self.currentHistoryPosition < [self.historyURLs count] - 1;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveForwardInHistory
{
  return [NSSet setWithObjects:@"currentHistoryPosition", @"historyURLs", nil];
}

- (id)_initWithDictionary:(NSMutableDictionary *)dictionary
{
  ASSERT(dictionary);
  self = [super init];
  if (!self)
    return nil;
  
  _mutableDictionary = dictionary;
  _mutableHistoryURLs = [[NSMutableArray alloc] init];
  if (![_mutableDictionary objectForKey:_historyURLsKey])
    [_mutableDictionary setObject:[[NSMutableArray alloc] init] forKey:_historyURLsKey];
  
  if (![(NSArray *)[_mutableDictionary objectForKey:_historyURLsKey] count]) {
    NSURL *projectsURL = [ArtCodeURL artCodeURLWithProject:nil item:nil path:artCodeURLProjectListPath];
    [[_mutableDictionary objectForKey:_historyURLsKey] addObject:projectsURL.absoluteString];
    [_mutableHistoryURLs addObject:projectsURL];
  } else {
    for (NSString *string in [_mutableDictionary objectForKey:_historyURLsKey])
      [_mutableHistoryURLs addObject:[NSURL URLWithString:string]];
  }

  // Set the history point
  if (![_mutableDictionary objectForKey:_currentHistoryPositionKey]) {
    [_mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:0] forKey:_currentHistoryPositionKey];
  }
  
  ASSERT(_mutableDictionary == dictionary);
  ASSERT([_mutableTabDictionaries indexOfObject:_mutableDictionary] != NSNotFound);
  
  // Force the population of currentProject and currentItem.
  [self _loadFirstValidProjectItem];
  
  return self;
}

- (id)init
{
  return [self _initWithDictionary:nil];
}

- (void)pushURL:(NSURL *)url
{
  ASSERT(url);
  // Moving in case of no previous history
  if (![(NSArray *)[_mutableDictionary objectForKey:_historyURLsKey] count])
  {
    [[_mutableDictionary objectForKey:_historyURLsKey] addObject:[url absoluteString]];
    [_mutableHistoryURLs addObject:url];
    [self _moveFromURL:nil toURL:url completionHandler:^(BOOL success) {
      self.currentHistoryPosition = 0;
    }];
    return;
  }
  
  [self willChangeValueForKey:@"historyURLs"];
  // Adding path to history and move forward
  NSUInteger lastPosition = [self.historyURLs count] - 1;
  if (self.currentHistoryPosition < lastPosition)
  {
    NSRange rangeToDelete = NSMakeRange(self.currentHistoryPosition + 1, lastPosition - self.currentHistoryPosition);
    [[_mutableDictionary objectForKey:_historyURLsKey] removeObjectsInRange:rangeToDelete];
    [_mutableHistoryURLs removeObjectsInRange:rangeToDelete];
  }
  [[_mutableDictionary objectForKey:_historyURLsKey] addObject:[url absoluteString]];
  [_mutableHistoryURLs addObject:url];
  [self didChangeValueForKey:@"historyURLs"];
  
  [self moveForwardInHistory];
}

- (void)moveBackInHistory
{
  if (!self.canMoveBackInHistory)
    return;
  
  // Get the history position before we initiate the move so it's consistent
  NSUInteger historyPositionBeforeMove = self.currentHistoryPosition;    
  [self _moveFromURL:self.currentURL toURL:[_mutableHistoryURLs objectAtIndex:self.currentHistoryPosition - 1] completionHandler:^(BOOL success) {
    self.currentHistoryPosition = historyPositionBeforeMove - 1;
  }];
}

- (void)moveForwardInHistory
{
  if (!self.canMoveForwardInHistory)
    return;
  
  // Get the history position before we initiate the move so it's consistent
  NSUInteger historyPositionBeforeMove = self.currentHistoryPosition;
  [self _moveFromURL:self.currentURL toURL:[_mutableHistoryURLs objectAtIndex:self.currentHistoryPosition + 1] completionHandler:^(BOOL success) {
    self.currentHistoryPosition = historyPositionBeforeMove + 1;
  }];
}

#pragma mark - Private Methods

- (void)_moveFromURL:(NSURL *)fromURL toURL:(NSURL *)toURL completionHandler:(void (^)(BOOL))completionHandler {
  if ([toURL isArtCodeURL]) {
    self.currentDocSet = nil;
    
    // Handle changes to art code urls
    id fromProjectUUID = [fromURL artCodeProjectUUID];
    id toProjectUUID = [toURL artCodeProjectUUID];
    id toItemUUID = [toURL artCodeItemUUID];
    
    // Check if we're changing projects, and if the project we're changing to exists
    BOOL isChangingProject = NO;
    ACProject *fromProject = [ACProject projectWithUUID:fromProjectUUID];
    ACProject *toProject = [ACProject projectWithUUID:toProjectUUID];
    if (fromProject != toProject) {
      isChangingProject = YES;
    }
    
    // If both are true, we need to make an async load, else we load synchronous
    if (isChangingProject && toProject)
    {
      self.loading = YES;
      void (^openToProject)(BOOL) = ^(BOOL _) {
        [toProject openWithCompletionHandler:^(BOOL success) {
          if (success) {
            self.currentProject = toProject;
            if (toItemUUID)
              self.currentItem = [toProject itemWithUUID:toItemUUID];
          } else {
            self.currentProject = nil;
            self.currentItem = nil;
          }
          completionHandler(success);
          self.loading = NO;
        }];
      };
      if (fromProject) {
        [fromProject closeWithCompletionHandler:openToProject];
      } else {
        openToProject(YES);
      }
    }
    else if (toProject)
    {
      // If we're here, the project is the same 
      self.currentItem = [toProject itemWithUUID:toItemUUID];
      completionHandler(YES);
    }
    else {
      // If we're here, we're changing to an URL without a project
      self.currentProject = nil;
      self.currentItem = nil;
      completionHandler(YES);
    }
  } else if ([toURL.scheme isEqualToString:@"docset"]) {
    // Handle changes to docset urls
    self.currentDocSet = toURL.docSet;
    self.currentProject = nil;
    self.currentItem = nil;
    completionHandler(self.currentDocSet != nil);
  } else {
    ASSERT(NO); // URL not handled
  }
}

- (void)_loadFirstValidProjectItem {
  [self _moveFromURL:nil toURL:self.currentURL completionHandler:^(BOOL success) {
    if (!success) {
      // In case the project couldn't be opened, remove the current history element and try to load the last one
      [[_mutableDictionary objectForKey:_historyURLsKey] removeLastObject];
      [_mutableHistoryURLs removeLastObject];
      self.currentHistoryPosition = self.currentHistoryPosition - 1;
      [self _loadFirstValidProjectItem];
    }
  }];
}

- (void)_removeHistoryEntriesContainingUUID:(id)uuid {
  // Get the indexes of history entries to remove, also removes identical URLs adjiacent to one another
  NSMutableIndexSet *removeIndexed = NSMutableIndexSet.new;
  __block NSString *lastURLString = nil;
  [(NSArray *)[_mutableDictionary objectForKey:_historyURLsKey] enumerateObjectsUsingBlock:^(NSString *URLString, NSUInteger idx, BOOL *stop) {
    if ([URLString rangeOfString:uuid].location != NSNotFound
        || [lastURLString isEqualToString:URLString]) {
      [removeIndexed addIndex:idx];
    } else {
      lastURLString = URLString;
    }
  }];
  // Exit if nothing done
  if (removeIndexed.count == 0)
    return;
  
  [self willChangeValueForKey:@"historyURLs"];
  NSURL *currentURL = self.currentURL;
  // Remove history entries
  [[_mutableDictionary objectForKey:_historyURLsKey] removeObjectsAtIndexes:removeIndexed];
  [_mutableHistoryURLs removeObjectsAtIndexes:removeIndexed];
  // Adjust current history position
  NSInteger newHistoryPosition = (NSInteger)self.currentHistoryPosition;
  NSInteger hisotryCount = (NSInteger)_mutableHistoryURLs.count;
  while (newHistoryPosition >= hisotryCount || [removeIndexed containsIndex:newHistoryPosition]) {
    newHistoryPosition--;
  }
  // We may not find a new position, in which case the history is completely erased and the tab considered not valid anymore
  if (newHistoryPosition < 0) {
    [_mutableHistoryURLs removeAllObjects];
    [[_mutableDictionary objectForKey:_historyURLsKey] removeAllObjects];
    [ArtCodeTab removeTab:self];
  } else {
    [self _moveFromURL:currentURL toURL:[_mutableHistoryURLs objectAtIndex:newHistoryPosition] completionHandler:^(BOOL success) {
      self.currentHistoryPosition = newHistoryPosition;
    }];
  }
  [self didChangeValueForKey:@"historyURLs"];
}

@end

#pragma mark

@implementation UIViewController (ArtCodeTab)

static void *artCodeTabKey;

- (ArtCodeTab *)artCodeTab
{
  ArtCodeTab *tab = objc_getAssociatedObject(self, &artCodeTabKey);
  if (tab)
    return tab;
  
  UIViewController *controller = self;
  do {
    controller = controller.parentViewController;
    tab = objc_getAssociatedObject(controller, &artCodeTabKey);
  } while (tab == nil && controller != nil);
  return tab;
}

- (void)setArtCodeTab:(ArtCodeTab *)artCodeTab
{
  objc_setAssociatedObject(self, &artCodeTabKey, artCodeTab, OBJC_ASSOCIATION_ASSIGN);
}

@end
