//
//  NSArray+ECAdditions.m
//  ECFoundation
//
//  Created by Nicola Peduzzi on 26/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSArray+ECAdditions.h"
#import "NSString+ECAdditions.h"

@interface ScoreForAbbreviationWrapper : NSObject {
@public
    id value;
    NSIndexSet *hitMask;
    float score;
}

- (id)initWithValue:(id)v score:(float)s hitMask:(NSIndexSet *)h;

@end

@implementation NSArray (ECAdditions)

- (NSArray *)sortedArrayUsingScoreForAbbreviation:(NSString *)abbreviation resultHitMasks:(NSArray *__autoreleasing *)resultHitMasks extrapolateTargetStringBlock:(NSString *(^)(id))targetStringBlock
{
    // Sort array using wrappers
    NSMutableArray *wrappers = [NSMutableArray arrayWithCapacity:[self count]];
    NSIndexSet *hitmask = nil;
    for (id elem in self)
    {
        float score = [(targetStringBlock ? targetStringBlock(elem) : (NSString *)elem) scoreForAbbreviation:abbreviation hitMask:&hitmask];
        if (score > 0.0)
        {
            [wrappers addObject:[[ScoreForAbbreviationWrapper alloc] initWithValue:elem score:score hitMask:hitmask]];
        }
    }
    [wrappers sortedArrayUsingSelector:@selector(compare:)];
    
    // Craft result arrays
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[wrappers count]];
    NSMutableArray *resultMasks = nil;
    if (resultHitMasks)
        resultMasks = [NSMutableArray arrayWithCapacity:[wrappers count]];
    for (ScoreForAbbreviationWrapper *w in wrappers)
    {
        [result addObject:w->value];
        [resultMasks addObject:w->hitMask];
    }
    
    // Return
    if (resultHitMasks)
        *resultHitMasks = [resultMasks copy];
    return [result copy];
}

@end


@implementation ScoreForAbbreviationWrapper

- (id)initWithValue:(id)v score:(float)s hitMask:(NSIndexSet *)h
{
    if ((self = [super init]))
    {
        value = v;
        score = s;
        hitMask = h;
    }
    return self;
}

- (NSComparisonResult)compare:(ScoreForAbbreviationWrapper *)wrapper
{
    if (self->score > wrapper->score)
        return NSOrderedAscending;
    else if (self->score < wrapper->score)
        return NSOrderedDescending;
    return [self->value compare:wrapper->value];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]])
        return NO;
    return [self->value isEqual:((ScoreForAbbreviationWrapper *)object)->value];
}

@end