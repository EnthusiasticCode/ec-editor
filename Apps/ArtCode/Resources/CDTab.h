//
//  CDTab.h
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDHistoryItem;

@interface CDTab : NSManagedObject

@property (nonatomic) int16_t index;
@property (nonatomic) int16_t currentHistoryPosition;
@property (nonatomic, retain) NSOrderedSet *historyItems;
@end

@interface CDTab (CoreDataGeneratedAccessors)

- (void)insertObject:(CDHistoryItem *)value inHistoryItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHistoryItemsAtIndex:(NSUInteger)idx;
- (void)insertHistoryItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHistoryItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHistoryItemsAtIndex:(NSUInteger)idx withObject:(CDHistoryItem *)value;
- (void)replaceHistoryItemsAtIndexes:(NSIndexSet *)indexes withHistoryItems:(NSArray *)values;
- (void)addHistoryItemsObject:(CDHistoryItem *)value;
- (void)removeHistoryItemsObject:(CDHistoryItem *)value;
- (void)addHistoryItems:(NSOrderedSet *)values;
- (void)removeHistoryItems:(NSOrderedSet *)values;
@end
