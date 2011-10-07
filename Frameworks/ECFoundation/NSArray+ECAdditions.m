//
//  NSArray+ECAdditions.m
//  ECFoundation
//
//  Created by Uri Baghin on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSArray+ECAdditions.h"
#import <objc/runtime.h>

#warning Test this ASAP, not even sure it works, if it doesn't rollback to the implementation in commit b4dc482082331f83438b0ea8a589cfeecf894e21

static const void * ECArrayCleaningSortKeyAssociation;

@implementation NSArray (ECArrayCleaning)

- (NSArray *)cleanedArrayUsingBlock:(NSNumber *(^)(id))scoreForObject
{
    return [self cleanedArrayUsingBlock:scoreForObject breakoffScore:[NSNumber numberWithFloat:0.0]];
}

- (NSArray *)cleanedArrayUsingBlock:(NSNumber *(^)(id))scoreForObject breakoffScore:(NSNumber *)breakoffScore
{
    return [self cleanedArrayUsingBlock:scoreForObject breakoffScore:breakoffScore additionalSortDescriptors:nil];
}

- (NSArray *)cleanedArrayUsingBlock:(NSNumber *(^)(id))scoreForObject breakoffScore:(NSNumber *)breakoffScore additionalSortDescriptors:(NSArray *)additionalSortDescriptors
{
    NSMutableArray *cleanedArray = [NSMutableArray arrayWithArray:self];
    [cleanedArray cleanUsingBlock:scoreForObject breakoffScore:breakoffScore additionalSortDescriptors:additionalSortDescriptors];
    return [cleanedArray copy];
}

@end

@implementation NSMutableArray (ECArrayCleaning)

- (void)cleanUsingBlock:(NSNumber *(^)(id))scoreForObject
{
    [self cleanUsingBlock:scoreForObject breakoffScore:[NSNumber numberWithFloat:0.0]];
}

- (void)cleanUsingBlock:(NSNumber *(^)(id))scoreForObject breakoffScore:(NSNumber *)breakoffScore
{
    [self cleanUsingBlock:scoreForObject breakoffScore:breakoffScore additionalSortDescriptors:nil];
}

- (void)cleanUsingBlock:(NSNumber *(^)(id))scoreForObject breakoffScore:(NSNumber *)breakoffScore additionalSortDescriptors:(NSArray *)additionalSortDescriptors
{
    ECASSERT(scoreForObject);
    [self filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSNumber *score = scoreForObject(evaluatedObject);
        if ([score compare:breakoffScore] != NSOrderedDescending)
            return NO;
        objc_setAssociatedObject(evaluatedObject, &ECArrayCleaningSortKeyAssociation, score, OBJC_ASSOCIATION_RETAIN);
        return YES;
    }]];
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithArray:additionalSortDescriptors];
    [sortDescriptors insertObject:[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO comparator:^NSComparisonResult(id obj1, id obj2) {
        return [objc_getAssociatedObject(obj1, ECArrayCleaningSortKeyAssociation) compare:objc_getAssociatedObject(obj2, ECArrayCleaningSortKeyAssociation)];
    }] atIndex:0];
    [self sortUsingDescriptors:sortDescriptors];
    for (id object in self)
        objc_setAssociatedObject(object, ECArrayCleaningSortKeyAssociation, nil, OBJC_ASSOCIATION_ASSIGN);
}

@end
