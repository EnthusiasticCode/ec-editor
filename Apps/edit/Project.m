//
//  Project.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Project.h"
#import "File.h"
#import "Folder.h"
#import "Tab.h"
#import "Target.h"

@implementation Project
@dynamic projectFiles;
@dynamic projectFolders;
@dynamic tabs;
@dynamic targets;

- (void)addProjectFilesObject:(File *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"projectFiles"] addObject:value];
    [self didChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeProjectFilesObject:(File *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"projectFiles"] removeObject:value];
    [self didChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addProjectFiles:(NSSet *)value
{
    [self willChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"projectFiles"] unionSet:value];
    [self didChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeProjectFiles:(NSSet *)value
{
    [self willChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"projectFiles"] minusSet:value];
    [self didChangeValueForKey:@"projectFiles" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (void)addProjectFoldersObject:(Folder *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"projectFolders"] addObject:value];
    [self didChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeProjectFoldersObject:(Folder *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"projectFolders"] removeObject:value];
    [self didChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addProjectFolders:(NSSet *)value
{
    [self willChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"projectFolders"] unionSet:value];
    [self didChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeProjectFolders:(NSSet *)value
{
    [self willChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"projectFolders"] minusSet:value];
    [self didChangeValueForKey:@"projectFolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
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
