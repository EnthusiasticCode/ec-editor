//
//  Tab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTab.h"
#import "ArtCodeURL.h"
#import "ArtCodeProject.h"
#import "NSURL+Utilities.h"
#import <objc/runtime.h>

static NSString * const _plistFileName = @"Tabs.plist";
static NSString * const _historyURLsKey = @"HistoryURLs";
static NSString * const _currentHistoryPositionKey = @"currentHistoryPosition";

static NSURL *_plistURL;
static NSMutableArray *_mutableTabDictionaries;
static NSMutableArray *_mutableTabs;

@interface ArtCodeTab ()
{
    NSMutableDictionary *_mutableDictionary;
    NSMutableArray *_mutableHistoryURLs;
}
- (id)_initWithDictionary:(NSMutableDictionary *)dictionary;
@end

@implementation ArtCodeTab

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
    [self willChangeValueForKey:@"currentHistoryPosition"];
    [_mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:currentHistoryPosition] forKey:_currentHistoryPositionKey];
    [self didChangeValueForKey:@"currentHistoryPosition"];
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
    ECASSERT(dictionary);
    self = [super init];
    if (!self)
        return nil;
    _mutableDictionary = dictionary;
    _mutableHistoryURLs = [[NSMutableArray alloc] init];
    if (![_mutableDictionary objectForKey:_historyURLsKey])
        [_mutableDictionary setObject:[[NSMutableArray alloc] init] forKey:_historyURLsKey];
    if (![[_mutableDictionary objectForKey:_historyURLsKey] count])
    {
        [[_mutableDictionary objectForKey:_historyURLsKey] addObject:[[ArtCodeURL projectsDirectory] absoluteString]];
        [_mutableHistoryURLs addObject:[ArtCodeURL projectsDirectory]];
    }
    else
    {
        for (NSString *string in [_mutableDictionary objectForKey:_historyURLsKey])
            [_mutableHistoryURLs addObject:[NSURL URLWithString:string]];
    }
    if (![_mutableDictionary objectForKey:_currentHistoryPositionKey])
        [_mutableDictionary setObject:[NSNumber numberWithUnsignedInteger:0] forKey:_currentHistoryPositionKey];
    ECASSERT(_mutableDictionary == dictionary);
    ECASSERT([_mutableTabDictionaries indexOfObject:_mutableDictionary] != NSNotFound);
    return self;
}

- (id)init
{
    return [self _initWithDictionary:nil];
}

- (void)pushURL:(NSURL *)url
{
    ECASSERT(url);
    if (![[_mutableDictionary objectForKey:_historyURLsKey] count])
    {
        [[_mutableDictionary objectForKey:_historyURLsKey] addObject:[url absoluteString]];
        [_mutableHistoryURLs addObject:url];
        self.currentHistoryPosition = 0;
        return;
    }
    NSUInteger lastPosition = [self.historyURLs count] - 1;
    if (self.currentHistoryPosition < lastPosition)
    {
        NSRange rangeToDelete = NSMakeRange(self.currentHistoryPosition + 1, lastPosition - self.currentHistoryPosition);
        [[_mutableDictionary objectForKey:_historyURLsKey] removeObjectsInRange:rangeToDelete];
        [_mutableHistoryURLs removeObjectsInRange:rangeToDelete];
    }
    [[_mutableDictionary objectForKey:_historyURLsKey] addObject:[url absoluteString]];
    [_mutableHistoryURLs addObject:url];
    self.currentHistoryPosition += 1;
}

- (void)moveBackInHistory
{
    if (self.canMoveBackInHistory)
        self.currentHistoryPosition -= 1;
}

- (void)moveForwardInHistory
{
    if (self.canMoveForwardInHistory)
        self.currentHistoryPosition += 1;
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
