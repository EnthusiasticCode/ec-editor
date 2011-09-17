//
//  ACTabController.m
//  tab
//
//  Created by Nicola Peduzzi on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTabController.h"
#import "ACTabNavigationController.h"
#import "ACTab.h"
#import "ACApplication.h"

static void * const ACTabControllerTabCurrentURLObserving;

@interface ACTabController ()
@property (nonatomic, weak) UIViewController *tabViewController;
@end

@implementation ACTabController {
    // TODO substitute with state
//    NSMutableArray *historyURLs;
//    NSUInteger historyPointIndex;
    
    BOOL dataSourceHasShouldChangeCurrentViewControllerForURL;
    BOOL delegateHasDidChangeURLPreviousViewController;
}

#pragma mark - Properties

@synthesize dataSource, delegate;
@synthesize parentTabNavigationController;
@synthesize tabButton, tabViewController, tab = _tab;

- (void)setDataSource:(id<ACTabControllerDataSource>)aDatasource
{
    dataSource = aDatasource;

    dataSourceHasShouldChangeCurrentViewControllerForURL = [dataSource respondsToSelector:@selector(tabController:shouldChangeCurrentViewController:forURL:)];
}

- (void)setDelegate:(id<ACTabControllerDelegate>)aDelegate
{
    delegate = aDelegate;
    
    delegateHasDidChangeURLPreviousViewController = [delegate respondsToSelector:@selector(tabController:didChangeURL:previousViewController:)];
}

- (void)setTab:(ACTab *)tab
{
    if (tab == _tab)
        return;
    [self willChangeValueForKey:@"tab"];
    [_tab removeObserver:self forKeyPath:@"currentURL" context:ACTabControllerTabCurrentURLObserving];
    _tab = tab;
    [_tab addObserver:self forKeyPath:@"currentURL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:ACTabControllerTabCurrentURLObserving];
    [self didChangeValueForKey:@"tab"];
}

- (BOOL)isCurrentTabController
{
    return parentTabNavigationController.currentTabController == self;
}

- (NSUInteger)position
{
    return [self.tab.application.tabs indexOfObject:self.tab];
}

- (UIViewController *)tabViewController
{
    if (tabViewController == nil)
    {
        ECASSERT(dataSource != nil);
        ECASSERT(self.tab.currentURL != nil);
        tabViewController = [dataSource tabController:self viewControllerForURL:self.tab.currentURL];
    }
    return tabViewController;
}

- (BOOL)isTabViewControllerLoaded
{
    return tabViewController != nil;
}

- (void)dealloc
{
    [_tab removeObserver:self forKeyPath:@"currentURL" context:ACTabControllerTabCurrentURLObserving];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != ACTabControllerTabCurrentURLObserving)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    // TODO: stink! accessing an instance variable to avoid lazy instantiation
    UIViewController *previousViewController = tabViewController;
    self.tabViewController = nil;
    if (delegateHasDidChangeURLPreviousViewController)
        [self.delegate tabController:self didChangeURL:[change objectForKey:NSKeyValueChangeNewKey] previousViewController:previousViewController];
}

#pragma mark - Create Tab Controllers

- (id)initWithDataSource:(id<ACTabControllerDataSource>)aDatasource tab:(ACTab *)tab
{
    ECASSERT(tab != nil);
    
    if ((self = [super init]))
    {
        self.dataSource = aDatasource;
        self.tab = tab;
    }
    return self;
}

#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone
{
    [self.tab.application insertTabAtIndex:self.position + 1];
    ACTab *newTab = [self.tab.application.tabs objectAtIndex:self.position + 1];
    [newTab pushURL:self.tab.currentURL];
    return [[ACTabController alloc] initWithDataSource:dataSource tab:newTab];
}

@end
