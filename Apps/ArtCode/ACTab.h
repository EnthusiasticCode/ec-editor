//
//  ACTab.h
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACHistoryItem, ACProject;

@interface ACTab : NSManagedObject

@property (nonatomic) int16_t currentHistoryPosition;
@property (nonatomic) int16_t index;
@property (nonatomic, strong) NSOrderedSet *historyItems;
@property (nonatomic, strong) ACProject *project;
@end

@interface ACTab (CoreDataGeneratedAccessors)

- (void)insertObject:(ACHistoryItem *)value inHistoryItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHistoryItemsAtIndex:(NSUInteger)idx;
- (void)insertHistoryItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHistoryItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHistoryItemsAtIndex:(NSUInteger)idx withObject:(ACHistoryItem *)value;
- (void)replaceHistoryItemsAtIndexes:(NSIndexSet *)indexes withHistoryItems:(NSArray *)values;
- (void)addHistoryItemsObject:(ACHistoryItem *)value;
- (void)removeHistoryItemsObject:(ACHistoryItem *)value;
- (void)addHistoryItems:(NSOrderedSet *)values;
- (void)removeHistoryItems:(NSOrderedSet *)values;
@end
