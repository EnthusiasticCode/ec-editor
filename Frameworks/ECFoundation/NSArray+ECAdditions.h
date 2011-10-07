//
//  NSArray+ECAdditions.h
//  ECFoundation
//
//  Created by Uri Baghin on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ECAdditions)

/// Returns an array obtained by sorting the elements of the receiver based on the return value of the given block, and by removing all elements for which the block returns a value equal or lower than the given breakoff point.
/// Additional sort descriptors may be specified to sort objects which have the same score, but they cannot have selectors or comparators.
- (NSArray *)cleanedArrayUsingBlock:(float (^)(id object))scoreForObject;
- (NSArray *)cleanedArrayUsingBlock:(float (^)(id object))scoreForObject breakoffScore:(float)breakoffScore;
- (NSArray *)cleanedArrayUsingBlock:(float (^)(id object))scoreForObject breakoffScore:(float)breakoffScore additionalSortDescriptors:(NSArray *)sortDescriptors;

@end
