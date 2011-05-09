//
//  Node.m
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Node.h"
#import "NameWord.h"
#import "Node.h"


@implementation Node
@dynamic name;
@dynamic tag;
@dynamic index;
@dynamic collapsed;
@dynamic type;
@dynamic nameWords;
@dynamic parent;
@dynamic children;

- (void)addNameWordsObject:(NameWord *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"nameWords"] addObject:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeNameWordsObject:(NameWord *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"nameWords"] removeObject:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addNameWords:(NSSet *)value {    
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"nameWords"] unionSet:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeNameWords:(NSSet *)value {
    [self willChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"nameWords"] minusSet:value];
    [self didChangeValueForKey:@"nameWords" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}



- (void)addChildrenObject:(Node *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"children" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"children"] addObject:value];
    [self didChangeValueForKey:@"children" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeChildrenObject:(Node *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"children" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"children"] removeObject:value];
    [self didChangeValueForKey:@"children" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addChildren:(NSSet *)value {    
    [self willChangeValueForKey:@"children" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"children"] unionSet:value];
    [self didChangeValueForKey:@"children" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeChildren:(NSSet *)value {
    [self willChangeValueForKey:@"children" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"children"] minusSet:value];
    [self didChangeValueForKey:@"children" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
