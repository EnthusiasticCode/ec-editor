//
//  CDFile.m
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CDFile.h"
#import "CDBookmark.h"
#import "CDHistoryItem.h"
#import "CDUndoItem.h"


@implementation CDFile
@dynamic path;
@dynamic undoItems;
@dynamic bookmarks;
@dynamic historyItems;

- (void)addUndoItemsObject:(CDUndoItem *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"undoItems"] addObject:value];
    [self didChangeValueForKey:@"undoItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeUndoItemsObject:(CDUndoItem *)value {
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


- (void)addBookmarksObject:(CDBookmark *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"bookmarks"] addObject:value];
    [self didChangeValueForKey:@"bookmarks" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeBookmarksObject:(CDBookmark *)value {
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


- (void)addHistoryItemsObject:(CDHistoryItem *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"historyItems"] addObject:value];
    [self didChangeValueForKey:@"historyItems" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeHistoryItemsObject:(CDHistoryItem *)value {
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
