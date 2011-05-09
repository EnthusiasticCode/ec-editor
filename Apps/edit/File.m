//
//  File.m
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "File.h"
#import "Bookmark.h"
#import "HistoryItem.h"
#import "UndoItem.h"


@implementation File
@dynamic path;
@dynamic bookmarks;
@dynamic undoItems;
@dynamic historyItems;

- (void)addBookmarksObject:(Bookmark *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"bookmarks"] addObject:value];
    [self didChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeBookmarksObject:(Bookmark *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"bookmarks"] removeObject:value];
    [self didChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addBookmarks:(NSSet *)value {    
    [self willChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"bookmarks"] unionSet:value];
    [self didChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeBookmarks:(NSSet *)value {
    [self willChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"bookmarks"] minusSet:value];
    [self didChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (void)addUndoItemsObject:(UndoItem *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"undoItems"] addObject:value];
    [self didChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeUndoItemsObject:(UndoItem *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"undoItems"] removeObject:value];
    [self didChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addUndoItems:(NSSet *)value {    
    [self willChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"undoItems"] unionSet:value];
    [self didChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeUndoItems:(NSSet *)value {
    [self willChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"undoItems"] minusSet:value];
    [self didChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (void)addHistoryItemsObject:(HistoryItem *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"historyItems"] addObject:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeHistoryItemsObject:(HistoryItem *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"historyItems"] removeObject:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addHistoryItems:(NSSet *)value {    
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"historyItems"] unionSet:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeHistoryItems:(NSSet *)value {
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"historyItems"] minusSet:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
