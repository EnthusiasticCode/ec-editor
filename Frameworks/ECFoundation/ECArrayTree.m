//
//  ECIndexPathTrie.m
//  edit
//
//  Created by Uri Baghin on 5/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECArrayTree.h"

@interface NSIndexPath (LastIndex)
- (NSUInteger)lastIndex;
@end

@implementation NSIndexPath (LastIndex)
- (NSUInteger)lastIndex
{
    return [self indexAtPosition:[self length] - 1];
}
@end

@implementation ECArrayTreeNode
@synthesize children;
@synthesize object;

- (void)dealloc
{
    self.children = nil;
    self.object = nil;
    [super dealloc];
}

- (NSUInteger)count
{
    NSUInteger count = object ? 1 : 0;
    for (ECArrayTreeNode *childNode in children)
        count += [childNode count];
    return count;
}

- (NSUInteger)countAtDepth:(NSUInteger)depth
{
    if (depth == 0)
        return object ? 1 : 0;
    NSUInteger count = 0;
    for (ECArrayTreeNode *child in children)
        count += [child countAtDepth:depth - 1];
    return count;
}

- (ECArrayTreeNode *)nodeAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger maxDepth = [indexPath length];
    ECArrayTreeNode *currentNode = self;
    for (NSUInteger depth = 0; depth < maxDepth; ++depth)
        currentNode = [currentNode.children objectAtIndex:[indexPath indexAtPosition:depth]];
    return currentNode;
}

- (ECArrayTreeNode *)parentNodeOfIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger maxDepth = [indexPath length] - 1;
    ECArrayTreeNode *currentNode = self;
    for (NSUInteger depth = 0; depth < maxDepth; ++depth)
        currentNode = [currentNode.children objectAtIndex:[indexPath indexAtPosition:depth]];
    return currentNode;
}

- (NSArray *)allObjects
{
    NSMutableArray *array = [NSMutableArray array];
    if (object)
        [array addObject:object];
    for (ECArrayTreeNode *child in children)
        [array addObjectsFromArray:[child allObjects]];
    return array;
}

- (NSArray *)objectsAtDepth:(NSUInteger)depth
{
    if (depth == 0)
        return [NSArray arrayWithObject:object];
    NSMutableArray *array = [NSMutableArray array];
    for (ECArrayTreeNode *child in children)
        [array addObjectsFromArray:[child objectsAtDepth:depth - 1]];
    return array;
}

- (NSArray *)allIndexPaths
{
    // TODO: no way of walking the tree recursively while creating indexpaths since they're immutable and it would create a million of them
    return nil;
}

- (NSArray *)indexPathsAtDepth:(NSUInteger)depth
{
    // TODO: no way of walking the tree recursively while creating indexpaths since they're immutable and it would create a million of them
    return nil;
}

+ (id)nodeWithObject:(id)object
{
    id node = [self alloc];
    node = [node init];
    [node setObject:object];
    return [node autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    ECMutableArrayTreeNode *node = [ECMutableArrayTreeNode nodeWithObject:object];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[children count]];
    for (ECArrayTreeNode *child in children)
        [array addObject:[[child mutableCopyWithZone:zone] autorelease]];
    node.children = array;
    return [node retain];
}

@end

@implementation ECMutableArrayTreeNode

@synthesize children = mutableChildren;

- (NSMutableArray *)children
{
    if (!mutableChildren)
        mutableChildren = [[NSMutableArray alloc] init];
    return mutableChildren;
}

- (ECMutableArrayTreeNode *)nodeAtIndexPath:(NSIndexPath *)indexPath
{
    return (ECMutableArrayTreeNode *)[super nodeAtIndexPath:indexPath];
}

- (ECMutableArrayTreeNode *)parentNodeOfIndexPath:(NSIndexPath *)indexPath
{
    return (ECMutableArrayTreeNode *)[super parentNodeOfIndexPath:indexPath];
}

@end

#pragma mark -

@interface ECArrayTree ()
@property (nonatomic, retain) ECArrayTreeNode *rootNode;
- (NSIndexPath *)_offsetIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ECArrayTree

@synthesize offset;
@synthesize rootNode;

- (ECArrayTreeNode *)rootNode
{
    if (!rootNode)
        rootNode = [[ECArrayTreeNode alloc] init];
    return rootNode;
}

- (void)dealloc
{
    self.offset = nil;
    self.rootNode = nil;
    [super dealloc];
}

+ (id)arrayTree
{
    id arrayTree = [self alloc];
    arrayTree = [arrayTree init];
    return [arrayTree autorelease];
}

- (NSIndexPath *)_offsetIndexPath:(NSIndexPath *)indexPath
{
    if (!self.offset || !indexPath)
        return indexPath;
    NSUInteger numIndexes = [indexPath length];
    NSUInteger numOffsetIndexes = [self.offset length];
    NSUInteger *offsetIndexes = malloc(numIndexes * sizeof(NSUInteger));
    for (NSUInteger i = 0; i < numIndexes; ++i)
        if (i < numOffsetIndexes)
            offsetIndexes[i] = [indexPath indexAtPosition:i] - [self.offset indexAtPosition:i];
        else
            offsetIndexes[i] = [indexPath indexAtPosition:i];
    NSIndexPath *offsetIndexPath = [NSIndexPath indexPathWithIndexes:offsetIndexes length:numIndexes];
    free(offsetIndexes);
    return offsetIndexPath;
}

- (NSUInteger)count
{
    return [self.rootNode count];
}

- (NSUInteger)countAtDepth:(NSUInteger)depth
{
    return [self.rootNode countAtDepth:depth];
}

- (NSUInteger)countForIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] count];
}

- (NSUInteger)countAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] countAtDepth:depth];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath)
        return self.rootNode.object;
    return [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] object];
}

- (NSArray *)allObjects
{
    return [self.rootNode allObjects];
}

- (NSArray *)objectsAtDepth:(NSUInteger)depth
{
    return [self.rootNode objectsAtDepth:depth];
}

- (NSArray *)objectsForIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] allObjects];
}

- (NSArray *)objectsAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] objectsAtDepth:depth];
}

- (NSArray *)allIndexPaths
{
    return [self.rootNode allIndexPaths];
}

- (NSArray *)indexPathsAtDepth:(NSUInteger)depth
{
    return [self.rootNode indexPathsAtDepth:depth];
}

- (NSArray *)indexPathsForIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] allObjects];
}

- (NSArray *)indexPathsAtDepth:(NSUInteger)depth forIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] indexPathsAtDepth:depth];
}

- (id)copyWithZone:(NSZone *)zone
{
    ECArrayTree *arrayTree = [ECArrayTree allocWithZone:zone];
    arrayTree = [arrayTree init];
    arrayTree.rootNode = [self.rootNode copyWithZone:zone];
    return arrayTree;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    ECMutableArrayTree *arrayTree = [ECMutableArrayTree allocWithZone:zone];
    arrayTree = [arrayTree init];
    arrayTree.rootNode = [self.rootNode mutableCopyWithZone:zone];
    return arrayTree;
}

@end

@interface ECMutableArrayTree ()
@property (nonatomic, retain) ECMutableArrayTreeNode *rootNode;
@end

@implementation ECMutableArrayTree

@synthesize rootNode = mutableRootNode;

- (ECMutableArrayTreeNode *)rootNode
{
    if (!mutableRootNode)
        mutableRootNode = [[ECMutableArrayTreeNode alloc] init];
    return mutableRootNode;
}

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    [[[self.rootNode parentNodeOfIndexPath:indexPath] children] insertObject:[ECArrayTreeNode nodeWithObject:object] atIndex:[indexPath lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    [[[self.rootNode parentNodeOfIndexPath:indexPath] children] removeObjectAtIndex:[indexPath lastIndex]];
}

- (void)replaceObjectAtIndexPath:(NSIndexPath *)indexPath withObject:(id)object
{
    [[self.rootNode nodeAtIndexPath:[self _offsetIndexPath:indexPath]] setObject:object];
}

- (void)addObject:(id)object toIndexPath:(NSIndexPath *)indexPath
{
    [[[self.rootNode parentNodeOfIndexPath:[self _offsetIndexPath:indexPath]] children] addObject:[ECArrayTreeNode nodeWithObject:object]];
}

- (void)removeLastObjectFromIndexPath:(NSIndexPath *)indexPath
{
    [[[self.rootNode parentNodeOfIndexPath:[self _offsetIndexPath:indexPath]] children] removeLastObject];
}

- (void)removeAllObjects
{
    self.rootNode = [[[ECMutableArrayTree alloc] init] autorelease];
}

- (void)moveObjectsAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *nodeIndexPath in indexPaths)
    {
        nodeIndexPath = [self _offsetIndexPath:nodeIndexPath];
        ECMutableArrayTreeNode *node = [self.rootNode parentNodeOfIndexPath:nodeIndexPath];
        [array addObject:[node.children objectAtIndex:[nodeIndexPath lastIndex]]];
        [node.children removeObjectAtIndex:[nodeIndexPath lastIndex]];
    }
    [[[self.rootNode parentNodeOfIndexPath:indexPath] children] insertObjects:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([indexPath lastIndex], [array count])]];
}

@end