//
//  CDFile.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDNode.h"

@class CDBookmark, CDHistoryItem, CDUndoItem;

@interface CDFile : CDNode {
@private
}
@property (nonatomic, retain) NSSet *bookmarks;
@property (nonatomic, retain) NSSet *historyItems;
@property (nonatomic, retain) NSSet *undoItems;
@end

@interface CDFile (CoreDataGeneratedAccessors)
- (void)addBookmarksObject:(CDBookmark *)value;
- (void)removeBookmarksObject:(CDBookmark *)value;
- (void)addBookmarks:(NSSet *)value;
- (void)removeBookmarks:(NSSet *)value;
- (void)addHistoryItemsObject:(CDHistoryItem *)value;
- (void)removeHistoryItemsObject:(CDHistoryItem *)value;
- (void)addHistoryItems:(NSSet *)value;
- (void)removeHistoryItems:(NSSet *)value;
- (void)addUndoItemsObject:(CDUndoItem *)value;
- (void)removeUndoItemsObject:(CDUndoItem *)value;
- (void)addUndoItems:(NSSet *)value;
- (void)removeUndoItems:(NSSet *)value;

@end
