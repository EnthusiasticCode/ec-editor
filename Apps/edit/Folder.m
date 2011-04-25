//
//  Folder.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Folder.h"
#import "File.h"
#import "Folder.h"
#import "Group.h"


@implementation Folder
@dynamic collapsed;
@dynamic groups;
@dynamic files;
@dynamic subfolders;
@dynamic parent;

- (void)addGroupsObject:(Group *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"groups"] addObject:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeGroupsObject:(Group *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"groups"] removeObject:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addGroups:(NSSet *)value
{
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"groups"] unionSet:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeGroups:(NSSet *)value
{
    [self willChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"groups"] minusSet:value];
    [self didChangeValueForKey:@"groups" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (void)addFilesObject:(File *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"files"] addObject:value];
    [self didChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeFilesObject:(File *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"files"] removeObject:value];
    [self didChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addFiles:(NSSet *)value
{
    [self willChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"files"] unionSet:value];
    [self didChangeValueForKey:@"files" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeFiles:(NSSet *)value
{
    [self willChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"files"] minusSet:value];
    [self didChangeValueForKey:@"files" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (void)addSubfoldersObject:(Folder *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subfolders"] addObject:value];
    [self didChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeSubfoldersObject:(Folder *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"subfolders"] removeObject:value];
    [self didChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addSubfolders:(NSSet *)value
{
    [self willChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subfolders"] unionSet:value];
    [self didChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeSubfolders:(NSSet *)value
{
    [self willChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"subfolders"] minusSet:value];
    [self didChangeValueForKey:@"subfolders" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

@end
