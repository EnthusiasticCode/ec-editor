//
//  ACTab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTab.h"
#import "ACApplication.h"
#import "ACHistoryItem.h"


@implementation ACTab

@dynamic currentHistoryPosition;
@dynamic application;
@dynamic historyItems;

- (NSURL *)currentURL
{
    return [[self.historyItems objectAtIndex:self.currentHistoryPosition] URL];
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
        ACHistoryItem *historyItem = [NSEntityDescription insertNewObjectForEntityForName:@"HistoryItem" inManagedObjectContext:self.managedObjectContext];
        historyItem.tab = self;
        historyItem.URL = url;
        return;
    }
    NSUInteger lastPosition = [self.historyItems count] - 1;
    if (self.currentHistoryPosition < lastPosition)
    {
        NSArray *historyItemsToDelete = [[self.historyItems array] subarrayWithRange:NSMakeRange(self.currentHistoryPosition + 1, lastPosition - self.currentHistoryPosition)];
        for (ACHistoryItem *historyItem in historyItemsToDelete)
        {
            historyItem.tab = nil;
            [self.managedObjectContext deleteObject:historyItem];
        }
    }
    ACHistoryItem *historyItem = [NSEntityDescription insertNewObjectForEntityForName:@"HistoryItem" inManagedObjectContext:self.managedObjectContext];
    historyItem.tab = self;
    historyItem.URL = url;
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
