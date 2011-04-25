//
//  Tab.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Tab.h"
#import "Project.h"

@implementation Tab
@dynamic customPosition;
@dynamic project;
@dynamic historyItems;

- (void)addHistoryItemsObject:(NSManagedObject *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"historyItems"] addObject:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeHistoryItemsObject:(NSManagedObject *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"historyItems"] removeObject:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addHistoryItems:(NSSet *)value
{
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"historyItems"] unionSet:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeHistoryItems:(NSSet *)value
{
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"historyItems"] minusSet:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
