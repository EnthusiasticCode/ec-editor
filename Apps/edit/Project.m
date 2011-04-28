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

- (void)addProjectFoldersObject:(Folder *)value
{
    [self addObject:value forOrderedKey:@"projectFolders"];
}

- (void)removeProjectFoldersObject:(Folder *)value
{
    [self removeObject:value forOrderedKey:@"projectFolders"];
}

- (void)addProjectFolders:(NSSet *)value
{
    [self addObjects:value forOrderedKey:@"projectFolders"];
}

- (void)removeProjectFolders:(NSSet *)value
{
    [self addObjects:value forOrderedKey:@"projectFolders"];
}

- (NSArray *)orderedProjectFolders
{
    return [self valueForOrderedKey:@"projectFolders"];
}

@end
