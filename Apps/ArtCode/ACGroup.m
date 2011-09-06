//
//  ACGroup.m
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACGroup.h"
#import "ACNode.h"


@implementation ACGroup

@dynamic expanded;
@dynamic children;

@dynamic concrete;

- (NSURL *)fileURL
{
    NSURL *fileURL = self.parent.fileURL;
    if (self.concrete)
        fileURL = [fileURL URLByAppendingPathComponent:self.name];
    return fileURL;
}

- (void)setConcrete:(BOOL)concrete
{
    ECASSERT(NO); // NYI
}

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [[self mutableOrderedSetValueForKey:@"children"] moveObjectsAtIndexes:indexes toIndex:index];
}

- (void)exchangeChildAtIndex:(NSUInteger)fromIndex withChildAtIndex:(NSUInteger)toIndex
{
    [[self mutableOrderedSetValueForKey:@"children"] exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

@end
