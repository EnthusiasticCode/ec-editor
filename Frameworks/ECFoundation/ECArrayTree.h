//
//  ECArrayTree.h
//  edit
//
//  Created by Uri Baghin on 5/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECArrayTree : NSObject <NSCopying, NSMutableCopying>
- (NSUInteger)count;
- (NSUInteger)countAtDepth:(NSUInteger)depth;
- (NSUInteger)countForIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)countAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)allObjects;
- (NSArray *)objectsForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)objectsAtDepth:(NSUInteger)depth;
- (NSArray *)objectsAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath;
+ (id)arrayTree;
@end

@interface ECMutableArrayTree : ECArrayTree
- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)replaceObjectAtIndexPath:(NSIndexPath *)indexPath withObject:(id)object;
- (void)addObject:(id)object toIndexPath:(NSIndexPath *)indexPath;
- (void)removeLastObjectFromIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectsAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath;
@end
