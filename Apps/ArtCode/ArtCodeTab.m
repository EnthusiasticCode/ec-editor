//
//  Tab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"

#import "DocSet.h"
#import "DocSetDownloadManager.h"

#import <objc/runtime.h>

static NSString * const _tabListKey = @"ArtCodeTabList";
static NSString * const _currentTabKey = @"ArtCodeTabCurrent";
static NSString * const _historyURLsKey = @"HistoryURLs";
static NSString * const _currentHistoryPositionKey = @"currentHistoryPosition";

static NSMutableArray *_systemTabDictionaries;
static NSMutableArray *_systemTabs;

NSString * const ArtCodeTabDidChangeAllTabsNotification = @"ArtCodeTabDidChangeAllTabs";

#pragma mark -

@interface ArtCodeTab ()

@property (nonatomic, getter = isLoading) BOOL loading;
@property (nonatomic, strong) ArtCodeProject *currentProject;
@property (nonatomic, strong) DocSet *currentDocSet;

- (id)_initWithDictionary:(NSMutableDictionary *)dictionary;

/// Moves the current URL for the tab and populate current project and item if neccessary.
- (void)_moveFromURL:(ArtCodeLocation *)fromURL toURL:(ArtCodeLocation *)toURL;

@end

#pragma mark -

@implementation ArtCodeTab {
  NSMutableDictionary *_mutableDictionary;
  // This array is maintained in parallel with _mutableDictionary's _historyURLsKey key to have NSURLs instead of strings
  NSMutableArray *_mutableHistoryURLs;
}

@synthesize loading = _loading, currentProject = _currentProject, currentDocSet = _currentDocSet;

#pragma mark - Class methods

+ (void)initialize
{
  if (self != [ArtCodeTab class])
    return;
  
  // Load persitent history
  _systemTabDictionaries = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:_tabListKey]];
  if (!_systemTabDictionaries) {
    _systemTabDictionaries = [[NSMutableArray alloc] init];
  }
  
  // Create tabs
  _systemTabs = [[NSMutableArray alloc] init];
  if (![_systemTabDictionaries count]) {
    [self insertTab:[self blankTab] atIndex:0];
  } else {
    for (NSMutableDictionary *dictionary in _systemTabDictionaries) {
      [_systemTabs addObject:[[self alloc] _initWithDictionary:dictionary]];
    }
  }
}

+ (NSArray *)allTabs {
  return [_systemTabs copy];
}

+ (void)insertTab:(ArtCodeTab *)tab atIndex:(NSUInteger)index {
  ASSERT(index >= 0 && index <= _systemTabs.count);
  
  // Update user defaults
  [_systemTabDictionaries insertObject:tab->_mutableDictionary atIndex:index];
  [[NSUserDefaults standardUserDefaults] setObject:_systemTabDictionaries forKey:_tabListKey];

  // Update working array
  [_systemTabs insertObject:tab atIndex:index];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:ArtCodeTabDidChangeAllTabsNotification object:self];
}

+ (void)moveTabAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
  if (fromIndex == toIndex)
    return;
  
  ArtCodeTab *tab = [_systemTabs objectAtIndex:fromIndex];
  
  // Update user defaults
  [_systemTabDictionaries removeObjectAtIndex:fromIndex];
  [_systemTabDictionaries insertObject:tab->_mutableDictionary atIndex:toIndex];
  [[NSUserDefaults standardUserDefaults] setObject:_systemTabDictionaries forKey:_tabListKey];
  
  // Update working array
  [_systemTabs removeObjectAtIndex:fromIndex];
  [_systemTabs insertObject:tab atIndex:toIndex];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:ArtCodeTabDidChangeAllTabsNotification object:self];
}

+ (void)removeTabAtIndex:(NSUInteger)tabIndex {
  ASSERT(tabIndex >= 0 && tabIndex <= _systemTabs.count);
  
  // Update user defaults
  [_systemTabDictionaries removeObjectAtIndex:tabIndex];
  [[NSUserDefaults standardUserDefaults] setObject:_systemTabDictionaries forKey:_tabListKey];
  
  // Update working array
  [_systemTabs removeObjectAtIndex:tabIndex];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:ArtCodeTabDidChangeAllTabsNotification object:self];
}

+ (ArtCodeTab *)blankTab
{
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  ArtCodeTab *newTab = [[self alloc] _initWithDictionary:dictionary]; 
  return newTab;
}

+ (ArtCodeTab *)duplicateTab:(ArtCodeTab *)tab
{
  ASSERT(tab);
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:0], _currentHistoryPositionKey, [NSMutableArray arrayWithObject:[[tab->_mutableDictionary objectForKey:_historyURLsKey] objectAtIndex:[[tab->_mutableDictionary objectForKey:_currentHistoryPositionKey] unsignedIntegerValue]]], _historyURLsKey, nil];
  ArtCodeTab *newTab = [[self alloc] _initWithDictionary:dictionary];
  return newTab;
}

+ (NSUInteger)currentTabIndex {
  return [[[NSUserDefaults standardUserDefaults] objectForKey:_currentTabKey] unsignedIntegerValue];
}

+ (void)setCurrentTabIndex:(NSUInteger)currentTabIndex {
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:currentTabIndex] forKey:_currentTabKey];
}

#pragma mark - Properties

- (NSUInteger)tabIndex {
  return [_systemTabs indexOfObject:self];
}

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

- (ArtCodeLocation *)currentLocation
{
  return [_mutableHistoryURLs objectAtIndex:self.currentHistoryPosition];
}

+ (NSSet *)keyPathsForValuesAffectingcurrentLocation
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
    ArtCodeLocation *projectsURL = [ArtCodeLocation locationWithType:ArtCodeLocationTypeProjectsList projectName:nil url:nil];
    [[_mutableDictionary objectForKey:_historyURLsKey] addObject:projectsURL.stringRepresentation];
    [_mutableHistoryURLs addObject:projectsURL];
  } else {
    for (NSString *string in [_mutableDictionary objectForKey:_historyURLsKey])
      [_mutableHistoryURLs addObject:[[ArtCodeLocation alloc] initWithStringRepresentation:string]];
  }

  // Set the history point
  if (![_mutableDictionary objectForKey:_currentHistoryPositionKey]) {
    [_mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:0] forKey:_currentHistoryPositionKey];
  }
  
  ASSERT(_mutableDictionary == dictionary);
  
  return self;
}

- (id)init
{
  return [self _initWithDictionary:nil];
}

- (void)remove {
  [ArtCodeTab removeTabAtIndex:self.tabIndex];
}

- (void)pushLocation:(ArtCodeLocation *)url
{
  ASSERT(url);
  // Moving in case of no previous history
  if (![(NSArray *)[_mutableDictionary objectForKey:_historyURLsKey] count])
  {
    [[_mutableDictionary objectForKey:_historyURLsKey] addObject:[url stringRepresentation]];
    [_mutableHistoryURLs addObject:url];
    [self _moveFromURL:nil toURL:url];
    self.currentHistoryPosition = 0;
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
  [[_mutableDictionary objectForKey:_historyURLsKey] addObject:[url stringRepresentation]];
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
  [self _moveFromURL:self.currentLocation toURL:[_mutableHistoryURLs objectAtIndex:self.currentHistoryPosition - 1]];
  self.currentHistoryPosition = historyPositionBeforeMove - 1;
}

- (void)moveForwardInHistory
{
  if (!self.canMoveForwardInHistory)
    return;
  
  // Get the history position before we initiate the move so it's consistent
  NSUInteger historyPositionBeforeMove = self.currentHistoryPosition;
  [self _moveFromURL:self.currentLocation toURL:[_mutableHistoryURLs objectAtIndex:self.currentHistoryPosition + 1]];
  self.currentHistoryPosition = historyPositionBeforeMove + 1;
}

#pragma mark - Private Methods

- (void)_moveFromURL:(ArtCodeLocation *)fromURL toURL:(ArtCodeLocation*)toURL {
  if (toURL.isArtCodeDocset) {
    // Handle changes to docset urls
//    self.currentDocSet = toURL.docSet; // get the docset
    self.currentProject = nil;
  } else {
    self.currentDocSet = nil;
    ArtCodeProject *fromProject = (ArtCodeProject *)fromURL.project;
    ArtCodeProject *toProject = (ArtCodeProject *)toURL.project;
    if (fromProject != toProject) {
      self.currentProject = toProject;
    }
  }
}

@end

#pragma mark

@implementation UIViewController (ArtCodeTab)

static void *artCodeTabKey;

- (ArtCodeTab *)artCodeTab {
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

- (void)setArtCodeTab:(ArtCodeTab *)artCodeTab {
  objc_setAssociatedObject(self, &artCodeTabKey, artCodeTab, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
