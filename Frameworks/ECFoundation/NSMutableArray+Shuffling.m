//
//  NSMutableArray+Shuffling.m
//  edit
//
//  Created by Uri Baghin on 4/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSMutableArray+Shuffling.h"

@implementation NSMutableArray (Shuffling)

- (void)moveObjectAtIndex:(NSUInteger)idx1 toIndex:(NSUInteger)idx2
{
    id object = [[self objectAtIndex:idx1] retain];
    if (idx1 > idx2)
    {
        [self removeObjectAtIndex:idx1];
        [self insertObject:object atIndex:idx2];
    }
    else
    {
        [self insertObject:object atIndex:idx2];
        [self removeObjectAtIndex:idx1];
    }
    [object release];
}

@end
