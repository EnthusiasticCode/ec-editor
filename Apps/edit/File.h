//
//  File.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Node.h"
#import "ECCodeView.h"
@class Bookmark, HistoryItem, UndoItem;

@interface File : Node <ECCodeViewDataSource>
@property (nonatomic, strong) NSSet *bookmarks;
@property (nonatomic, strong) NSSet *historyItems;
@property (nonatomic, strong) NSOrderedSet *undoItems;
@end

@interface File (CoreDataGeneratedAccessors)
- (void)addBookmarksObject:(Bookmark *)value;
- (void)removeBookmarksObject:(Bookmark *)value;
- (void)addBookmarks:(NSSet *)value;
- (void)removeBookmarks:(NSSet *)value;
- (void)addHistoryItemsObject:(HistoryItem *)value;
- (void)removeHistoryItemsObject:(HistoryItem *)value;
- (void)addHistoryItems:(NSSet *)value;
- (void)removeHistoryItems:(NSSet *)value;
- (void)addUndoItemsObject:(UndoItem *)value;
- (void)removeUndoItemsObject:(UndoItem *)value;
- (void)addUndoItems:(NSSet *)value;
- (void)removeUndoItems:(NSSet *)value;
@end
