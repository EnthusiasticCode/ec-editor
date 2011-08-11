//
//  CDNode.h
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDNode;

@interface CDNode : NSManagedObject

@property (nonatomic) BOOL expanded;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic) int16_t tag;
@property (nonatomic) int16_t type;
@property (nonatomic, retain) NSOrderedSet *children;
@property (nonatomic, retain) CDNode *parent;
@end

@interface CDNode (CoreDataGeneratedAccessors)

- (void)insertObject:(CDNode *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(CDNode *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;
- (void)addChildrenObject:(CDNode *)value;
- (void)removeChildrenObject:(CDNode *)value;
- (void)addChildren:(NSOrderedSet *)values;
- (void)removeChildren:(NSOrderedSet *)values;
@end
