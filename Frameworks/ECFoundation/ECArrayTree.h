//
//  ECArrayTree.h
//  edit
//
//  Created by Uri Baghin on 5/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//@interface ECArrayTree : NSObject <NSCopying, NSMutableCopying>
//@property (nonatomic, retain) NSIndexPath *offset;
//- (NSUInteger)count;
//- (NSUInteger)countAtDepth:(NSUInteger)depth;
//- (NSUInteger)countForIndexPath:(NSIndexPath *)indexPath;
//- (NSUInteger)countAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath;
//- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
//- (NSArray *)allObjects;
//- (NSArray *)objectsForIndexPath:(NSIndexPath *)indexPath;
//- (NSArray *)objectsAtDepth:(NSUInteger)depth;
//- (NSArray *)objectsAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath;
//- (NSArray *)allIndexPaths;
//- (NSArray *)indexPathsForIndexPath:(NSIndexPath *)indexPath;
//- (NSArray *)indexPathsAtDepth:(NSUInteger)depth;
//- (NSArray *)indexPathsAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath;
//+ (id)arrayTree;
//@end
//
//@interface ECMutableArrayTree : ECArrayTree
//@end

@interface ECArrayTree : NSObject <NSCopying, NSMutableCopying>
@property (nonatomic, retain) NSIndexPath *offset;
@property (nonatomic, retain) NSArray *children;
@property (nonatomic, retain) id object;
- (NSUInteger)count;
- (NSUInteger)countAtDepth:(NSUInteger)depth;
- (ECArrayTree *)nodeAtIndexPath:(NSIndexPath *)indexPath;
- (ECArrayTree *)parentNodeOfIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)allObjects;
- (NSArray *)objectsAtDepth:(NSUInteger)depth;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
+ (id)nodeWithObject:(id)object;
@end

@interface ECMutableArrayTree : ECArrayTree
@property (nonatomic, retain) NSMutableArray *children;
- (ECMutableArrayTree *)nodeAtIndexPath:(NSIndexPath *)indexPath;
- (ECMutableArrayTree *)parentNodeOfIndexPath:(NSIndexPath *)indexPath;
- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)replaceObjectAtIndexPath:(NSIndexPath *)indexPath withObject:(id)object;
- (void)addObject:(id)object toIndexPath:(NSIndexPath *)indexPath;
- (void)removeLastObjectFromIndexPath:(NSIndexPath *)indexPath;
- (void)removeAllObjects;
- (void)moveObjectsAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath;
@end