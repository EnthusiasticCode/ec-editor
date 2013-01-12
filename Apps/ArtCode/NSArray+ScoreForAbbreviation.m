//
//  NSArray+Additions.m
//  Foundation
//
//  Created by Nicola Peduzzi on 26/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSArray+ScoreForAbbreviation.h"
#import "NSString+ScoreForAbbreviation.h"

@implementation NSArray (ScoreForAbbreviation)

- (NSArray *)sortedArrayUsingScoreForAbbreviation:(NSString *)abbreviation extrapolateTargetStringBlock:(NSString *(^)(id))targetStringBlock {
	NSMutableArray *sortedArray = [NSMutableArray arrayWithCapacity:self.count];
	
	for (id object in self) {
		if (abbreviation == nil) {
			[sortedArray addObject:[RACTuple tupleWithObjects:object, nil]];
		} else {
			NSIndexSet *hitMask = nil;
			float score = [targetStringBlock ? targetStringBlock(object) : (NSString *)object scoreForAbbreviation:abbreviation hitMask:&hitMask];
			if (score > 0.0) [sortedArray addObject:[RACTuple tupleWithObjects:object, hitMask ?: RACTupleNil.tupleNil, @(score), nil]];
		}
	}
	
	[sortedArray sortUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
		NSNumber *score1 = tuple1.third;
		NSNumber *score2 = tuple2.third;
		
		if (score1.floatValue > score2.floatValue) {
			return NSOrderedAscending;
		} else if (score1.floatValue < score2.floatValue) {
			return NSOrderedDescending;
		} else {
			return NSOrderedSame;
		}
	}];
	
	return sortedArray;
}

@end
