//
//  Project.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Project.h"
#import "Node.h"
#import "Tab.h"
#import "Target.h"

@implementation Project
@dynamic nodes;
@dynamic tabs;
@dynamic targets;

- (void)addNodesObject:(Node *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"nodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"nodes"] addObject:value];
    [self didChangeValueForKey:@"nodes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeNodesObject:(Node *)value
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

- (void)addTabsObject:(Tab *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"tabs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"tabs"] addObject:value];
    [self didChangeValueForKey:@"tabs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeTabsObject:(Tab *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"tabs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"tabs"] removeObject:value];
    [self didChangeValueForKey:@"tabs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addTabs:(NSSet *)value
{
    [self willChangeValueForKey:@"tabs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"tabs"] unionSet:value];
    [self didChangeValueForKey:@"tabs" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeTabs:(NSSet *)value
{
    [self willChangeValueForKey:@"tabs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"tabs"] minusSet:value];
    [self didChangeValueForKey:@"tabs" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (void)addTargetsObject:(Target *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"targets" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"targets"] addObject:value];
    [self didChangeValueForKey:@"targets" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeTargetsObject:(Target *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"targets" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"targets"] removeObject:value];
    [self didChangeValueForKey:@"targets" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addTargets:(NSSet *)value
{
    [self willChangeValueForKey:@"targets" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"targets"] unionSet:value];
    [self didChangeValueForKey:@"targets" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeTargets:(NSSet *)value
{
    [self willChangeValueForKey:@"targets" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"targets"] minusSet:value];
    [self didChangeValueForKey:@"targets" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
