//
//  Tab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTab.h"
#import "Application.h"
#import "HistoryItem.h"
#import "ArtCodeProject.h"
#import <objc/runtime.h>


@implementation ArtCodeTab

@dynamic currentHistoryPosition, application, historyItems;
@synthesize currentProject;

- (NSURL *)currentURL
{
    return [[self.historyItems objectAtIndex:self.currentHistoryPosition] URL];
}

- (ArtCodeProject *)currentProject
{
    if (currentProject == nil)
    {
        NSString *projectName = [ArtCodeProject projectNameFromURL:self.currentURL isProjectRoot:NULL];
        if ([ArtCodeProject projectWithNameExists:projectName])
            currentProject = [ArtCodeProject projectWithName:projectName];
    }
    return currentProject;
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
    return self.currentHistoryPosition < [self.historyItems count] - 1;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveForwardInHistory
{
    return [NSSet setWithObjects:@"currentHistoryPosition", @"historyItems", nil];
}

- (void)pushURL:(NSURL *)url
{
    ECASSERT(url);
    if (![self.historyItems count])
    {
        HistoryItem *historyItem = [NSEntityDescription insertNewObjectForEntityForName:@"HistoryItem" inManagedObjectContext:self.managedObjectContext];
        historyItem.tab = self;
        historyItem.URL = url;
        return;
    }
    NSUInteger lastPosition = [self.historyItems count] - 1;
    if (self.currentHistoryPosition < lastPosition)
    {
        NSArray *historyItemsToDelete = [[self.historyItems array] subarrayWithRange:NSMakeRange(self.currentHistoryPosition + 1, lastPosition - self.currentHistoryPosition)];
        for (HistoryItem *historyItem in historyItemsToDelete)
        {
            historyItem.tab = nil;
            [self.managedObjectContext deleteObject:historyItem];
        }
    }
    HistoryItem *historyItem = [NSEntityDescription insertNewObjectForEntityForName:@"HistoryItem" inManagedObjectContext:self.managedObjectContext];
    historyItem.tab = self;
    historyItem.URL = url;
    self.currentHistoryPosition += 1;
    currentProject = nil;
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
