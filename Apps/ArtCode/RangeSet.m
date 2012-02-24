//
//  RangeSet.m
//  ArtCode
//
//  Created by Uri Baghin on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RangeSet.h"

@interface RangeSet ()
{
    @package
    NSUInteger _count;
    NSUInteger _capacity;
    NSRangePointer _contents;
}
- (NSUInteger)_indexOfFirstRangeOverlappingRange:(NSRange)range indexOfLastRange:(NSUInteger *)lastRangeIndex;
@end

@implementation RangeSet

- (id)initWithRangeSet:(RangeSet *)rangeSet
{
    UNIMPLEMENTED();
}

- (void)dealloc
{
    if (_contents)
        free(_contents);
}

- (NSUInteger)count
{
    return _count;
}

- (NSRange)rangeAtIndex:(NSUInteger)index
{
    if (index >= _count)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Index out of range." userInfo:nil];
    return _contents[index];
}

- (void)enumerateRangesWithBlock:(void (^)(NSRange, NSUInteger, BOOL *))block
{
    BOOL stop = NO;
    for (NSUInteger index = 0; index < _count; ++index)
    {
        block(_contents[index], index, &stop);
        if (stop)
            return;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    UNIMPLEMENTED();
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    UNIMPLEMENTED();
}

- (NSUInteger)_indexOfFirstRangeOverlappingRange:(NSRange)range indexOfLastRange:(NSUInteger *)lastRangeIndex
{
    NSUInteger firstRangeIndex = NSNotFound;
    for (NSUInteger index = 0; index < _count; ++index)
        if (range.location <= NSMaxRange(_contents[index]))
        {
            firstRangeIndex = index;
            break;
        }
    if (!lastRangeIndex)
        return firstRangeIndex;
    *lastRangeIndex = NSNotFound;
    for (NSUInteger index = _count; index > 0; --index)
        if (_contents[index - 1].location <= NSMaxRange(range))
        {
            *lastRangeIndex = index;
            break;
        }
    return firstRangeIndex;
}

@end

@implementation MutableRangeSet

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _capacity = 8;
    _contents = malloc(_capacity * sizeof(NSRange));
    return self;
}

- (void)addRange:(NSRange)range
{
    [self replaceRange:range withRange:range];
}

- (void)removeRange:(NSRange)range
{
    NSUInteger lastRangeIndex;
    NSUInteger firstRangeIndex = [self _indexOfFirstRangeOverlappingRange:range indexOfLastRange:&lastRangeIndex];
    // Inverted ranges means range doesn't overlap any ranges, we're done
    if (lastRangeIndex < firstRangeIndex || (firstRangeIndex == NSNotFound && lastRangeIndex == NSNotFound))
        return;
    // Check to see if we have some leftover after removing the range
    NSInteger headLeftover = range.location - _contents[firstRangeIndex].location;
    if (headLeftover < 0)
        headLeftover = 0;
    NSInteger tailLeftover = NSMaxRange(_contents[lastRangeIndex]) - NSMaxRange(range);
    if (tailLeftover < 0)
        tailLeftover = 0;
    if (firstRangeIndex == lastRangeIndex)
    {
        // If the range we're removing only overlaps one range we have to split it if we have both head and tail left over, otherwise we just adjust it
        if (headLeftover && tailLeftover)
        {
            if (_capacity == _count)
            {
                // We need to grow the contents array
                _capacity = _capacity * 2;
                _contents = realloc(_contents, _capacity * sizeof(NSRange));
            }
            // Insert a new range before the overlapping range and set it equal to it
            memmove(&_contents[firstRangeIndex + 1], &_contents[firstRangeIndex], (_count - firstRangeIndex) * sizeof(NSRange));
            _contents[firstRangeIndex] = _contents[firstRangeIndex + 1];
            // Adjust the first range for the head leftover
            _contents[firstRangeIndex].length -= NSIntersectionRange(range, _contents[firstRangeIndex]).length;
            // Adjust the second range for the tail leftover
            NSUInteger intersectionLength = NSIntersectionRange(range, _contents[lastRangeIndex]).length;
            _contents[firstRangeIndex + 1].location += intersectionLength;
            _contents[firstRangeIndex + 1].length -= intersectionLength;
        }
        else if (headLeftover)
        {
            _contents[firstRangeIndex].length -= NSIntersectionRange(range, _contents[firstRangeIndex]).length;
        }
        else if (tailLeftover)
        {
            NSUInteger intersectionLength = NSIntersectionRange(range, _contents[lastRangeIndex]).length;
            _contents[lastRangeIndex].location += intersectionLength;
            _contents[lastRangeIndex].length -= intersectionLength;
        }
    }
    else
    {
        // If the range we're removing overlaps more ranges we adjust the first and the last if needed and delete all the others
        if (headLeftover)
        {
            _contents[firstRangeIndex].length -= NSIntersectionRange(range, _contents[firstRangeIndex]).length;
        }
        if (tailLeftover)
        {
            NSUInteger intersectionLength = NSIntersectionRange(range, _contents[lastRangeIndex]).length;
            _contents[lastRangeIndex].location += intersectionLength;
            _contents[lastRangeIndex].length -= intersectionLength;
        }
        // The number of ranges to delete is the ranges [first, last[, minus the first if we have a head left over and plus the last if we don't have a tail left over
        NSUInteger rangesToDeleteCount = lastRangeIndex - firstRangeIndex - (headLeftover ? 1 : 0) + (tailLeftover ? 0 : 1);
        if (rangesToDeleteCount)
        {
            memmove(&_contents[firstRangeIndex + 1], &_contents[lastRangeIndex + 1], rangesToDeleteCount * sizeof(NSRange));
            _count -= rangesToDeleteCount;
        }
    }
}

- (void)insertRange:(NSRange)range
{
    [self replaceRange:NSMakeRange(range.location, 0) withRange:range];
}

- (void)deleteRange:(NSRange)range
{
    NSRange rangeToRemove = NSMakeRange(range.location, 0);
    [self replaceRange:range withRange:rangeToRemove];
    [self removeRange:rangeToRemove];
}

- (void)replaceRange:(NSRange)oldRange withRange:(NSRange)newRange
{
    ECASSERT(oldRange.location == newRange.location);
    // Get indexes of the first and last ranges containing oldRange
    NSUInteger lastRangeIndex;
    NSUInteger firstRangeIndex = [self _indexOfFirstRangeOverlappingRange:oldRange indexOfLastRange:&lastRangeIndex];
    NSInteger offset = newRange.length - oldRange.length;
    if (lastRangeIndex < firstRangeIndex || (firstRangeIndex == NSNotFound && lastRangeIndex == NSNotFound))
    {
        // Inverted ranges means the old range doesn't overlap with any of the existing ranges
        if (_capacity == _count)
        {
            // We need to grow the contents array
            _capacity = _capacity * 2;
            _contents = realloc(_contents, _capacity * sizeof(NSRange));
        }
        if (firstRangeIndex == NSNotFound)
        {
            // We didn't find a range greater than the old range, so the new range should be added at the end
            _contents[_count] = newRange;
        }
        else
        {
            // The first range is greater than the old range, so the new range should be inserted before the first range
            ECASSERT(lastRangeIndex == NSNotFound || lastRangeIndex == firstRangeIndex - 1);
            memmove(&_contents[firstRangeIndex + 1], &_contents[firstRangeIndex], (_count - firstRangeIndex) * sizeof(NSRange));
            _contents[firstRangeIndex] = newRange;
            for (NSUInteger index = firstRangeIndex + 1; index < _count + 1; ++index)
                _contents[index].location += offset;
        }
        ++_count;
    }
    else
    {
        // The old range overlaps one or more ranges
        // We count how much of the existing ranges is left over by the old range being replaced, if there's anything left over at all
        NSInteger headLeftover = oldRange.location - _contents[firstRangeIndex].location;
        if (headLeftover < 0)
            headLeftover = 0;
        NSInteger tailLeftover = NSMaxRange(_contents[lastRangeIndex]) - NSMaxRange(oldRange);
        if (tailLeftover < 0)
            tailLeftover = 0;
        // We update the first overlapped range to reflect the new range merged with any leftovers of the overlapped ranges
        _contents[firstRangeIndex].location = MIN(oldRange.location, _contents[firstRangeIndex].location);
        _contents[firstRangeIndex].length = newRange.length + headLeftover + tailLeftover;
        // We delete the other overlapped ranges if the old range overlapped more than one
        NSUInteger rangesToDeleteCount = lastRangeIndex - firstRangeIndex;
        if (rangesToDeleteCount)
        {
            memmove(&_contents[firstRangeIndex + 1], &_contents[lastRangeIndex + 1], rangesToDeleteCount * sizeof(NSRange));
            _count -= rangesToDeleteCount;
        }
        for (NSUInteger index = firstRangeIndex + 1; index < _count; ++index)
            _contents[index].location += offset;
    }
}

@end
