//
//  NSArray+ECAdditions.h
//  ECFoundation
//
//  Created by Uri Baghin on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Sorts elements of the array based on the return value of the given block , and removes all elements for which the block returns a value equal or lower than the given breakoff point.
/// Additional sort descriptors may be specified to sort objects which have the same score.

@interface NSArray (ECArrayCleaning)

- (NSArray *)cleanedArrayUsingBlock:(NSNumber *(^)(id object))scoreForObject;
- (NSArray *)cleanedArrayUsingBlock:(NSNumber *(^)(id object))scoreForObject breakoffScore:(NSNumber *)breakoffScore;
- (NSArray *)cleanedArrayUsingBlock:(NSNumber *(^)(id object))scoreForObject breakoffScore:(NSNumber *)breakoffScore additionalSortDescriptors:(NSArray *)additionalSortDescriptors;

@end

@interface NSMutableArray (ECArrayCleaning)

- (void)cleanUsingBlock:(NSNumber *(^)(id object))scoreForObject;
- (void)cleanUsingBlock:(NSNumber *(^)(id))scoreForObject breakoffScore:(NSNumber *)breakoffScore;
- (void)cleanUsingBlock:(NSNumber *(^)(id object))scoreForObject breakoffScore:(NSNumber *)breakoffScore additionalSortDescriptors:(NSArray *)additionalSortDescriptors;

@end
