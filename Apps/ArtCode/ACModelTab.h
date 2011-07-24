//
//  ACModelTab.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACModelHistoryItem;

@interface ACModelTab : NSManagedObject

@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSOrderedSet *historyItems;
@end

@interface ACModelTab (CoreDataGeneratedAccessors)

- (void)insertObject:(ACModelHistoryItem *)value inHistoryItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHistoryItemsAtIndex:(NSUInteger)idx;
- (void)insertHistoryItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHistoryItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHistoryItemsAtIndex:(NSUInteger)idx withObject:(ACModelHistoryItem *)value;
- (void)replaceHistoryItemsAtIndexes:(NSIndexSet *)indexes withHistoryItems:(NSArray *)values;
- (void)addHistoryItemsObject:(ACModelHistoryItem *)value;
- (void)removeHistoryItemsObject:(ACModelHistoryItem *)value;
- (void)addHistoryItems:(NSOrderedSet *)values;
- (void)removeHistoryItems:(NSOrderedSet *)values;
@end
