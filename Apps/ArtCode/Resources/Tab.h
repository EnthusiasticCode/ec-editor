//
//  Tab.h
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location, TabSet;

@interface Tab : NSManagedObject

@property (nonatomic) int16_t currentPosition;
@property (nonatomic, retain) NSOrderedSet *history;
@property (nonatomic, retain) TabSet *tabSet;
@end

@interface Tab (CoreDataGeneratedAccessors)

- (void)insertObject:(Location *)value inHistoryAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHistoryAtIndex:(NSUInteger)idx;
- (void)insertHistory:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHistoryAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHistoryAtIndex:(NSUInteger)idx withObject:(Location *)value;
- (void)replaceHistoryAtIndexes:(NSIndexSet *)indexes withHistory:(NSArray *)values;
- (void)addHistoryObject:(Location *)value;
- (void)removeHistoryObject:(Location *)value;
- (void)addHistory:(NSOrderedSet *)values;
- (void)removeHistory:(NSOrderedSet *)values;
@end
