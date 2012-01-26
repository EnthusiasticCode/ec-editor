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
    NSString *targetString;
    NSIndexSet *hitMask;
    float score;
}

- (id)initWithValue:(id)v targetString:(NSString *)t score:(float)s hitMask:(NSIndexSet *)h;

@end

@implementation NSArray (ECAdditions)

- (NSArray *)sortedArrayUsingScoreForAbbreviation:(NSString *)abbreviation resultHitMasks:(NSArray *__autoreleasing *)resultHitMasks extrapolateTargetStringBlock:(NSString *(^)(id))targetStringBlock
{
    // Sort array using wrappers
    NSMutableArray *wrappers = [NSMutableArray arrayWithCapacity:[self count]];
    NSIndexSet *hitmask = nil;
    for (id elem in self)
    {
        NSString *targetString = targetStringBlock ? targetStringBlock(elem) : (NSString *)elem;
        float score = [targetString scoreForAbbreviation:abbreviation hitMask:&hitmask];
        if (score > 0.0)
        {
            [wrappers addObject:[[ScoreForAbbreviationWrapper alloc] initWithValue:elem targetString:targetString score:score hitMask:hitmask]];
        }
    }
    [wrappers sortUsingSelector:@selector(compare:)];
    
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

- (id)initWithValue:(id)v targetString:(NSString *)t score:(float)s hitMask:(NSIndexSet *)h
{
    if ((self = [super init]))
    {
        value = v;
        targetString = t;
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
    return [self->targetString compare:wrapper->targetString];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]])
        return NO;
    return [self->targetString isEqual:((ScoreForAbbreviationWrapper *)object)->targetString];
}

@end