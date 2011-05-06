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

@interface ECArrayTree ()
- (NSIndexPath *)_offsetIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ECArrayTree
@synthesize offset;
@synthesize children;
@synthesize object;

- (void)dealloc
{
    self.children = nil;
    self.object = nil;
    [super dealloc];
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
    NSUInteger count = self.object ? 1 : 0;
    for (ECArrayTree *childNode in self.children)
        count += [childNode count];
    return count;
}

- (NSUInteger)countAtDepth:(NSUInteger)depth
{
    if (depth == 0)
        return self.object ? 1 : 0;
    NSUInteger count = 0;
    for (ECArrayTree *child in self.children)
        count += [child countAtDepth:depth - 1];
    return count;
}

- (ECArrayTree *)nodeAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    NSUInteger maxDepth = [indexPath length];
    ECArrayTree *currentNode = self;
    for (NSUInteger depth = 0; depth < maxDepth; ++depth)
        currentNode = [currentNode.children objectAtIndex:[indexPath indexAtPosition:depth]];
    return currentNode;
}

- (ECArrayTree *)parentNodeOfIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    NSUInteger maxDepth = [indexPath length] - 1;
    ECArrayTree *currentNode = self;
    for (NSUInteger depth = 0; depth < maxDepth; ++depth)
        currentNode = [currentNode.children objectAtIndex:[indexPath indexAtPosition:depth]];
    return currentNode;
}

- (NSArray *)allObjects
{
    NSMutableArray *array = [NSMutableArray array];
    if (self.object)
        [array addObject:self.object];
    for (ECArrayTree *child in self.children)
        [array addObjectsFromArray:[child allObjects]];
    return array;
}

- (NSArray *)objectsAtDepth:(NSUInteger)depth
{
    if (depth == 0)
        return [NSArray arrayWithObject:self.object];
    NSMutableArray *array = [NSMutableArray array];
    for (ECArrayTree *child in self.children)
        [array addObjectsFromArray:[child objectsAtDepth:depth - 1]];
    return array;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    return [[self nodeAtIndexPath:indexPath] object];
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
    ECMutableArrayTree *node = [ECMutableArrayTree nodeWithObject:self.object];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.children count]];
    for (ECArrayTree *child in self.children)
        [array addObject:[[child mutableCopyWithZone:zone] autorelease]];
    node.children = array;
    return [node retain];
}

@end

@implementation ECMutableArrayTree

@synthesize children = mutableChildren;

- (NSMutableArray *)children
{
    if (!mutableChildren)
        mutableChildren = [[NSMutableArray alloc] init];
    return mutableChildren;
}

- (ECMutableArrayTree *)nodeAtIndexPath:(NSIndexPath *)indexPath
{
    return (ECMutableArrayTree *)[super nodeAtIndexPath:indexPath];
}

- (ECMutableArrayTree *)parentNodeOfIndexPath:(NSIndexPath *)indexPath
{
    return (ECMutableArrayTree *)[super parentNodeOfIndexPath:indexPath];
}

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    [[[self parentNodeOfIndexPath:indexPath] children] insertObject:[ECMutableArrayTree nodeWithObject:object] atIndex:[indexPath lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    [[[self parentNodeOfIndexPath:indexPath] children] removeObjectAtIndex:[indexPath lastIndex]];
}

- (void)replaceObjectAtIndexPath:(NSIndexPath *)indexPath withObject:(id)object
{
    [[self nodeAtIndexPath:[self _offsetIndexPath:indexPath]] setObject:object];
}

- (void)addObject:(id)object toIndexPath:(NSIndexPath *)indexPath
{
    [[[self parentNodeOfIndexPath:[self _offsetIndexPath:indexPath]] children] addObject:[ECMutableArrayTree nodeWithObject:object]];
}

- (void)removeLastObjectFromIndexPath:(NSIndexPath *)indexPath
{
    [[[self parentNodeOfIndexPath:[self _offsetIndexPath:indexPath]] children] removeLastObject];
}

- (void)removeAllObjects
{
    self.object = nil;
    self.children = nil;
}

- (void)moveObjectsAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [self _offsetIndexPath:indexPath];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *nodeIndexPath in indexPaths)
    {
        nodeIndexPath = [self _offsetIndexPath:nodeIndexPath];
        ECMutableArrayTree *node = [self parentNodeOfIndexPath:nodeIndexPath];
        [array addObject:[node.children objectAtIndex:[nodeIndexPath lastIndex]]];
        [node.children removeObjectAtIndex:[nodeIndexPath lastIndex]];
    }
    [[[self parentNodeOfIndexPath:indexPath] children] insertObjects:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([indexPath lastIndex], [array count])]];
}

@end