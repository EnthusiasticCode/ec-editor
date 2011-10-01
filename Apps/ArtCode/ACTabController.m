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
#import "ACProjectTableController.h"
#import "ACFileTableController.h"
#import "ACCodeFileController.h"

static void * ACTabControllerTabCurrentURLObserving;

@interface ACTabController ()
@property (nonatomic, strong) UIViewController *tabViewController;
@end

@implementation ACTabController {
    // TODO substitute with state
//    NSMutableArray *historyURLs;
//    NSUInteger historyPointIndex;
    
    BOOL delegateHasDidChangeURLPreviousViewController;
}

#pragma mark - Properties

@synthesize delegate;
@synthesize parentTabNavigationController;
@synthesize tabButton, tabViewController, tab = _tab;

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
        NSURL *currentURL = self.tab.currentURL;
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        __block BOOL currentURLIsEqualToProjectsDirectory = NO;
        __block BOOL currentURLExists = NO;
        __block BOOL currentURLIsDirectory = NO;
        [fileCoordinator coordinateReadingItemAtURL:currentURL options:NSFileCoordinatorReadingResolvesSymbolicLink | NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
            currentURLIsEqualToProjectsDirectory = [newURL isEqual:[self.tab.application projectsDirectory]];
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            currentURLExists = [fileManager fileExistsAtPath:[newURL path] isDirectory:&currentURLIsDirectory];
        }];
        if (currentURLIsEqualToProjectsDirectory)
        {
            ACProjectTableController *projectTableController = [[ACProjectTableController alloc] init];
            projectTableController.projectsDirectory = currentURL;
            projectTableController.tab = self.tab;
            return projectTableController;
        }
        else if (currentURLExists)
        {
            if (currentURLIsDirectory)
            {
                ACFileTableController *fileTableController = [[ACFileTableController alloc] init];
                fileTableController.directory = currentURL;
                fileTableController.tab = self.tab;
                return fileTableController;
            }
            else
            {
                ACCodeFileController *codeFileController = [[ACCodeFileController alloc] init];
                codeFileController.fileURL = currentURL;
                codeFileController.tab = self.tab;
                return codeFileController;
            }
        }
    }
    ECASSERT(tabViewController); // should never return nil
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

- (id)initWithTab:(ACTab *)tab
{
    ECASSERT(tab != nil);
    
    if ((self = [super init]))
    {
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
    return [[ACTabController alloc] initWithTab:newTab];
}

@end
