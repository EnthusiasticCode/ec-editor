//
//  NameWord.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NameWord.h"

@implementation NameWord
@dynamic normalizedWord;
@dynamic nodes;

- (void)addNodesObject:(NSManagedObject *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"nodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"nodes"] addObject:value];
    [self didChangeValueForKey:@"nodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeNodesObject:(NSManagedObject *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"nodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"nodes"] removeObject:value];
    [self didChangeValueForKey:@"nodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addNodes:(NSSet *)value
{
    [self willChangeValueForKey:@"nodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"nodes"] unionSet:value];
    [self didChangeValueForKey:@"nodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeNodes:(NSSet *)value
{
    [self willChangeValueForKey:@"nodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"nodes"] minusSet:value];
    [self didChangeValueForKey:@"nodes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
