//
//  NSArray+ECAdditions.h
//  ECFoundation
//
//  Created by Nicola Peduzzi on 26/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ECAdditions)

/// Returns a sorted version of the array using score for abbreviation algorithm.
/// The returned array may be shorter than the original.
/// Hit masks for the abbreviations found are returned in a one to one array if the 
/// resultHitMasks parameter is not nil.
/// targetStringBlock is a block that will map an element of the original array to
/// a string that is than used by the algorithm; use nil for the identity map.
- (NSArray *)sortedArrayUsingScoreForAbbreviation:(NSString *)abbreviation resultHitMasks:(NSArray **)resultHitMasks extrapolateTargetStringBlock:(NSString *(^)(id element))targetStringBlock;

@end
