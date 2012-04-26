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

- (id)_initWithDictionary:(NSMutableDictionary *)dictionary;
- (void)_moveFromURL:(NSURL *)fromURL toURL:(NSURL *)toURL completionHandler:(void(^)(BOOL success))completionHandler;

@end

@implementation ArtCodeTab
{
  NSMutableDictionary *_mutableDictionary;
  NSMutableArray *_mutableHistoryURLs;
}

@synthesize loading = _loading, currentProject = _currentProject, currentItem = _currentItem;

#pragma mark - Class methods

+ (void)initialize
{
  if (self != [ArtCodeTab class])
    return;
  _plistURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_plistFileName];
  NSData *plistData = [NSData dataWithContentsOfURL:_plistURL options:NSDataReadingUncached error:NULL];
  if (plistData)
    _mutableTabDictionaries = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:0 error:NULL];
  if (!_mutableTabDictionaries)
    _mutableTabDictionaries = [[NSMutableArray alloc] init];
  _mutableTabs = [[NSMutableArray alloc] init];
  if (![_mutableTabDictionaries count])
    [self blankTab]; // no need to do anything with the return value, it will be automatically added to the class arrays
  else
    for (NSMutableDictionary *dictionary in _mutableTabDictionaries)
      [_mutableTabs addObject:[[self alloc] _initWithDictionary:dictionary]];
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
  NSMutableDictionary *dictionary = [tab->_mutableDictionary mutableCopy];
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

- (void)setCurrentHistoryPosition:(NSUInteger)currentHistoryPosition
{
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
  if (![(NSArray *)[_mutableDictionary objectForKey:_historyURLsKey] count])
  {
    NSURL *projectsURL = [ArtCodeURL artCodeURLWithProject:nil item:nil path:artCodeURLProjectListPath];
    [[_mutableDictionary objectForKey:_historyURLsKey] addObject:projectsURL.absoluteString];
    [_mutableHistoryURLs addObject:projectsURL];
  }
  else
  {
    for (NSString *string in [_mutableDictionary objectForKey:_historyURLsKey])
      [_mutableHistoryURLs addObject:[NSURL URLWithString:string]];
  }

  // Set the history point
  if (![_mutableDictionary objectForKey:_currentHistoryPositionKey]) {
    [_mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:0] forKey:_currentHistoryPositionKey];
  }
  
  ASSERT(_mutableDictionary == dictionary);
  ASSERT([_mutableTabDictionaries indexOfObject:_mutableDictionary] != NSNotFound);
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

- (void)reloadCurrentStatusWithCompletionHandler:(void (^)(BOOL))completionHandler {
  [self _moveFromURL:nil toURL:self.currentURL completionHandler:completionHandler];
}

#pragma mark - Private Methods

- (void)_moveFromURL:(NSURL *)fromURL toURL:(NSURL *)toURL completionHandler:(void (^)(BOOL))completionHandler
{
  NSArray *fromUUIDs = [fromURL artCodeUUIDs];
  NSArray *toUUIDs = [toURL artCodeUUIDs];
  
  // Check if we're changing projects, and if the project we're changing to exists
  BOOL changeProjects = NO;
  ACProject *toProject = nil;
  if ((fromUUIDs.count || toUUIDs.count) && ![(fromUUIDs.count ? [fromUUIDs objectAtIndex:0] : nil) isEqual:(toUUIDs.count ? [toUUIDs objectAtIndex:0] : nil)])
  {
    changeProjects = YES;
    if ([toUUIDs count] && [toUUIDs objectAtIndex:0])
      toProject = [ACProject projectWithUUID:[toUUIDs objectAtIndex:0]];
  }
  
  // If both are true, we need to make an async load, else we load synchronous
  if (changeProjects && toProject)
  {
    self.loading = YES;
    [toProject openWithCompletionHandler:^(BOOL success) {
      [self.currentProject closeWithCompletionHandler:nil];
      self.currentProject = nil;
      self.currentItem = nil;
      if (success)
      {
        self.currentProject = toProject;
        if ([toUUIDs count] > 1)
          self.currentItem = [toProject itemWithUUID:[toUUIDs objectAtIndex:1]];
      }
      completionHandler(success);
      self.loading = NO;
    }];
  }
  else
  {
    // If we're here, the project is the same
    self.currentItem = nil;
    if ([toUUIDs count] > 1)
      self.currentItem = [self.currentProject itemWithUUID:[toUUIDs objectAtIndex:1]];
    completionHandler(YES);
  }
}

@end


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
