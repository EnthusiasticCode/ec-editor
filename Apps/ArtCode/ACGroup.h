//
//  ACGroup.h
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACNode.h"

@class ACNode, ACFile;

@interface ACGroup : ACNode

@property (nonatomic) BOOL expanded;
@property (nonatomic, strong) NSOrderedSet *children;

@property (nonatomic, getter = isConcrete) BOOL concrete;

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeChildAtIndex:(NSUInteger)fromIndex withChildAtIndex:(NSUInteger)toIndex;

- (void)importFileFromURL:(NSURL *)fileURL completionHandler:(void (^)(BOOL success))completionHandler;
- (void)importFilesFromZIP:(NSURL *)ZIPFileURL completionHandler:(void (^)(BOOL success))completionHandler;

- (ACNode *)childWithName:(NSString *)name;

- (ACGroup *)insertChildGroupWithName:(NSString *)name atIndex:(NSUInteger)index;
- (ACFile *)insertChildFileWithName:(NSString *)name atIndex:(NSUInteger)index;

@end

@interface ACGroup (CoreDataGeneratedAccessors)

- (void)insertObject:(ACNode *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(ACNode *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;
- (void)addChildrenObject:(ACNode *)value;
- (void)removeChildrenObject:(ACNode *)value;
- (void)addChildren:(NSOrderedSet *)values;
- (void)removeChildren:(NSOrderedSet *)values;
@end
