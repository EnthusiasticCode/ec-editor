//
//  Target.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Target.h"
#import "File.h"
#import "Project.h"

@implementation Target
@dynamic name;
@dynamic sourceFiles;
@dynamic project;

- (void)addSourceFilesObject:(File *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"sourceFiles"] addObject:value];
    [self didChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeSourceFilesObject:(File *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"sourceFiles"] removeObject:value];
    [self didChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addSourceFiles:(NSSet *)value
{
    [self willChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"sourceFiles"] unionSet:value];
    [self didChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeSourceFiles:(NSSet *)value
{
    [self willChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"sourceFiles"] minusSet:value];
    [self didChangeValueForKey:@"sourceFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
