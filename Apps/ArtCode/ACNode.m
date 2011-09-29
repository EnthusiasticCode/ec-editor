//
//  ACNode.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNode.h"
#import "ACGroup.h"


@implementation ACNode

@dynamic name;
@dynamic tag;
@dynamic expanded;
@dynamic parent;
@dynamic children;

- (NSURL *)ACURL
{
    
}

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [[self mutableOrderedSetValueForKey:@"children"] moveObjectsAtIndexes:indexes toIndex:index];
}

- (void)exchangeChildAtIndex:(NSUInteger)fromIndex withChildAtIndex:(NSUInteger)toIndex
{
    [[self mutableOrderedSetValueForKey:@"children"] exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

- (ACGroup *)insertChildGroupWithName:(NSString *)name atIndex:(NSUInteger)index
{
    ECASSERT(name);
    ACGroup *childGroup = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:self.managedObjectContext];
    childGroup.parent = self;
    childGroup.name = name;
    return childGroup;
}

@end
