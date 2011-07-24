//
//  ACModelNode.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACModelHistoryItem, ACModelNode;

@interface ACModelNode : NSManagedObject

@property (nonatomic, retain) NSNumber * expanded;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSOrderedSet *children;
@property (nonatomic, retain) ACModelNode *parent;
@property (nonatomic, retain) NSSet *historyItems;
@end

@interface ACModelNode (CoreDataGeneratedAccessors)

- (void)insertObject:(ACModelNode *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(ACModelNode *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;
- (void)addChildrenObject:(ACModelNode *)value;
- (void)removeChildrenObject:(ACModelNode *)value;
- (void)addChildren:(NSOrderedSet *)values;
- (void)removeChildren:(NSOrderedSet *)values;
- (void)addHistoryItemsObject:(ACModelHistoryItem *)value;
- (void)removeHistoryItemsObject:(ACModelHistoryItem *)value;
- (void)addHistoryItems:(NSSet *)values;
- (void)removeHistoryItems:(NSSet *)values;

@end
