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
#import <objc/runtime.h>

static NSMutableArray *_mutableTabs;

@interface ArtCodeTab ()
{
    NSMutableArray *_mutableHistoryURLs;
}
- (id)_initWithTab:(ArtCodeTab *)tab;
@end

@implementation ArtCodeTab

#pragma mark - Class methods

+ (void)initialize
{
    _mutableTabs = [[NSMutableArray alloc] init];
    [_mutableTabs addObject:[self blankTab]];
}

+ (NSArray *)allTabs
{
    return [_mutableTabs copy];
}

+ (ArtCodeTab *)blankTab
{
    return [[self alloc] init];
}

+ (ArtCodeTab *)duplicateTab:(ArtCodeTab *)tab
{
    return [[self alloc] _initWithTab:tab];
}

+ (void)removeTab:(ArtCodeTab *)tab
{
    [_mutableTabs removeObject:tab];
}

#pragma mark - Properties

@synthesize currentHistoryPosition = _currentHistoryPosition;

- (NSArray *)historyURLs
{
    return [_mutableHistoryURLs copy];
}

- (NSURL *)currentURL
{
    return [self.historyURLs objectAtIndex:self.currentHistoryPosition];
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

- (id)_initWithTab:(ArtCodeTab *)tab
{
    self = [super init];
    if (!self)
        return nil;
    _mutableHistoryURLs = [tab.historyURLs mutableCopy];
    if (!_mutableHistoryURLs)
        _mutableHistoryURLs = [[NSMutableArray alloc] init];
    if (![_mutableHistoryURLs count])
        [_mutableHistoryURLs addObject:[ArtCodeURL projectsDirectory]];
    return self;
}

- (id)init
{
    return [self _initWithTab:nil];
}

- (void)pushURL:(NSURL *)url
{
    ECASSERT(url);
    if (![_mutableHistoryURLs count])
    {
        [_mutableHistoryURLs addObject:url];
        self.currentHistoryPosition = 0;
        return;
    }
    NSUInteger lastPosition = [self.historyURLs count] - 1;
    if (self.currentHistoryPosition < lastPosition)
        [_mutableHistoryURLs removeObjectsInRange:NSMakeRange(self.currentHistoryPosition + 1, lastPosition - self.currentHistoryPosition)];
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
