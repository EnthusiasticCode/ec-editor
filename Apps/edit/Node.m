//
//  Node.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Node.h"
#import "Folder.h"
#import "NameWord.h"

@implementation Node
@dynamic customPosition;
@dynamic path;
@dynamic name;
@dynamic nameWords;
@dynamic folder;
@dynamic project;

- (void)addNameWordsObject:(NameWord *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"nameWords"] addObject:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeNameWordsObject:(NameWord *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"nameWords"] removeObject:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addNameWords:(NSSet *)value
{
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"nameWords"] unionSet:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeNameWords:(NSSet *)value
{
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"nameWords"] minusSet:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
