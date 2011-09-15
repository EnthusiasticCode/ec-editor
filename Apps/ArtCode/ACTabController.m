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
#import "ACProject.h"

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

- (BOOL)isCurrentTabController
{
    return parentTabNavigationController.currentTabController == self;
}

- (NSUInteger)position
{
    return [self.tab.project.tabs indexOfObject:self.tab];
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
    [self.tab.project insertTabAtIndex:self.position + 1];
    ACTab *newTab = [self.tab.project.tabs objectAtIndex:self.position + 1];
    [newTab pushURL:self.tab.currentURL];
    return [[ACTabController alloc] initWithDataSource:dataSource tab:newTab];
}

@end
