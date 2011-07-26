//
//  ACTabController.m
//  tab
//
//  Created by Nicola Peduzzi on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTabController.h"
#import "ACTabNavigationController.h"

@implementation ACTabController {
    // TODO substitute with state
    NSMutableArray *historyURLs;
    NSUInteger historyPointIndex;
    
    struct {
        unsigned int hasShouldChangeCurrentViewControllerForURL : 1;
        unsigned int hasDidChangeURLPreviousViewController : 1;
        unsigned int reserved : 2;
    } delegateFlags;
}

#pragma mark - Properties

@synthesize dataSource, delegate;
@synthesize parentTabNavigationController;
@synthesize tabButton, tabViewController;
@synthesize historyURLs;

- (void)setDelegate:(id<ACTabControllerDelegate>)aDelegate
{
    delegate = aDelegate;
    
    delegateFlags.hasShouldChangeCurrentViewControllerForURL = [delegate respondsToSelector:@selector(tabController:shouldChangeCurrentViewController:forURL:)];
    delegateFlags.hasDidChangeURLPreviousViewController = [delegate respondsToSelector:@selector(tabController:didChangeURL:previousViewController:)];
}

- (NSUInteger)position
{
    return [parentTabNavigationController.tabControllers indexOfObject:self];
}

- (NSURL *)currentURL
{
    if (historyPointIndex >= [historyURLs count])
        return nil;
    
    return [historyURLs objectAtIndex:historyPointIndex];
}

- (BOOL)canMoveBack
{
    return historyPointIndex > 0;
}

- (BOOL)canMoveForward
{
    return [historyURLs count] > 1 && historyPointIndex < ([historyURLs count] - 1);
}

- (UIViewController *)tabViewController
{
    if (tabViewController == nil)
    {
        ECASSERT(dataSource != nil);
        ECASSERT([self currentURL] != nil);
        __autoreleasing UIViewController *viewController = [dataSource tabController:self viewControllerForURL:[self currentURL]];
        tabViewController = viewController;
    }
    return tabViewController;
}

- (BOOL)isTabViewControllerLoaded
{
    return tabViewController != nil;
}

#pragma mark - Create Tab Controllers

- (id)initWithURL:(NSURL *)initialURL
{
    ECASSERT(initialURL != nil);
    
    if ((self = [super init]))
    {
        historyURLs = [NSMutableArray new];
        [historyURLs addObject:initialURL];
    }
    return self;
}

#pragma mark - Managing Tab's History

- (void)pushURL:(NSURL *)url
{
    ECASSERT(url != nil);
    
    if (!historyURLs)
        historyURLs = [NSMutableArray new];
    
    // Remove forwars history
    if (historyPointIndex < ([historyURLs count] - 1))
    {
        [historyURLs removeObjectsInRange:NSMakeRange(historyPointIndex + 1, [historyURLs count] - historyPointIndex - 1)];
    }
    
    [historyURLs addObject:url];
    
    [self moveToHistoryURLAtIndex:[historyURLs count] - 1];
}

- (void)moveToHistoryURLAtIndex:(NSUInteger)URLIndex
{
    ECASSERT(URLIndex < [historyURLs count]);
    
    historyPointIndex = URLIndex;
    NSURL *currentURL = [historyURLs objectAtIndex:URLIndex];
    UIViewController *previousViewController = tabViewController;
    
    // Delete reference to current view controller
    if (!delegateFlags.hasShouldChangeCurrentViewControllerForURL
        || [delegate tabController:self shouldChangeCurrentViewController:previousViewController forURL:currentURL])
    {
        tabViewController = nil;
    }
    
    // Inform of URL change
    if (delegateFlags.hasDidChangeURLPreviousViewController)
        [delegate tabController:self didChangeURL:currentURL previousViewController:previousViewController];
}

- (void)moveBackInHistory
{
    if (![self canMoveBack])
        return;
    
    [self moveToHistoryURLAtIndex:historyPointIndex - 1];
}

- (void)moveForwardInHistory
{
    if (![self canMoveForward])
        return;
    
    [self moveToHistoryURLAtIndex:historyPointIndex + 1];
}

#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [[ACTabController alloc] initWithURL:[self currentURL]];
}

@end
