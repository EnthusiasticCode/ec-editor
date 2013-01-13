//
//  NSArray+Additions.h
//  Foundation
//
//  Created by Nicola Peduzzi on 26/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ScoreForAbbreviation)

// Filters and sorts an array by abbreviation score.
//
// abbreviation      - The string with which to score the objects in the array.
// targetStringBlock - An optional block used to calculate strings used for
//                     scoring the objects in the array.
//
// Returns a sorted array of triples of object, hit mask and score for every
// object that scores higher than 0.0.
- (NSArray *)sortedArrayUsingScoreForAbbreviation:(NSString *)abbreviation extrapolateTargetStringBlock:(NSString *(^)(id element))targetStringBlock;

@end
