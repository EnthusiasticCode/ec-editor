//
//  File.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "File.h"
#import "Bookmark.h"
#import "Folder.h"
#import "Group.h"
#import "HistoryItem.h"
#import "Project.h"
#import "Target.h"
#import "UndoItem.h"

@implementation File
@dynamic type;
@dynamic group;
@dynamic bookmarks;
@dynamic undoItems;
@dynamic historyItems;
@dynamic targets;
@dynamic folder;
@dynamic project;

- (void)addUndoItemsObject:(UndoItem *)value
{
    [self addObject:value forOrderedKey:@"undoItems"];
}

- (void)removeUndoItemsObject:(UndoItem *)value
{
    [self removeObject:value forOrderedKey:@"undoItems"];
}

- (void)addUndoItems:(NSSet *)value
{
    [self addObjects:value forOrderedKey:@"undoItems"];
}

- (void)removeUndoItems:(NSSet *)value
{
    [self removeObjects:value forOrderedKey:@"undoItems"];
}

- (NSArray *)orderedUndoItems
{
    return [self valueForOrderedKey:@"undoItems"];
}

@end
