//
//  ACTab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTab.h"
#import "ACHistoryItem.h"
#import "ACProject.h"


@implementation ACTab

@dynamic currentHistoryPosition;
@dynamic historyItems;
@dynamic project;

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
    NSUInteger lastPosition = [self.historyItems count] - 1;
    if (self.currentHistoryPosition < lastPosition)
    {
        NSMutableOrderedSet *historyItems = [self mutableOrderedSetValueForKey:@"historyItems"];
        [historyItems removeObjectsInRange:NSMakeRange(self.currentHistoryPosition, lastPosition - self.currentHistoryPosition)];
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
