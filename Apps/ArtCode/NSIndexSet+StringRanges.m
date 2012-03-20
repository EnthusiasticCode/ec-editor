//
//  NSIndexSet+StringRanges.m
//  ArtCode
//
//  Created by Uri Baghin on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSIndexSet+StringRanges.h"

@implementation NSIndexSet (StringRanges)

- (NSRange)firstRange
{
    __block NSRange firstRange = NSMakeRange(NSNotFound, 0);
    [self enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        firstRange = range;
        *stop = YES;
    }];
    return firstRange;
}

@end

@implementation NSMutableIndexSet (StringRanges)

- (void)insertIndexesInRange:(NSRange)range
{
    if (!range.length)
        return;
    [self shiftIndexesStartingAtIndex:range.location by:range.length];
    [self addIndexesInRange:range];
}

- (void)deleteIndexesInRange:(NSRange)range
{
    if (!range.length)
        return;
    [self removeIndexesInRange:range];
    [self shiftIndexesStartingAtIndex:NSMaxRange(range) by:-range.length];
}

- (void)replaceIndexesInRange:(NSRange)oldRange withIndexesInRange:(NSRange)newRange
{
    ASSERT(oldRange.location == newRange.location);
    if (oldRange.length)
        [self removeIndexesInRange:oldRange];
    [self shiftIndexesStartingAtIndex:oldRange.location by:newRange.length - oldRange.length];
    if (newRange.length)
        [self addIndexesInRange:newRange];
}

- (void)shiftIndexesByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange
{
    ASSERT(oldRange.location == newRange.location);
    NSInteger difference = oldRange.length - newRange.length;
    if (difference > 0)
        [self removeIndexesInRange:NSMakeRange(NSMaxRange(oldRange) - difference, difference)];
    [self shiftIndexesStartingAtIndex:NSMaxRange(oldRange) by:-difference];
}

@end
