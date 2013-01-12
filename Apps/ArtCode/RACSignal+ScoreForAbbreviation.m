//
//  RACSignal+ScoreForAbbreviation.m
//  ArtCode
//
//  Created by Uri Baghin on 12/01/2013.
//
//

#import "RACSignal+ScoreForAbbreviation.h"

#import "NSArray+ScoreForAbbreviation.h"

@implementation RACSignal (ScoreForAbbreviation)

- (RACSignal *)filterArraySignalByAbbreviation:(RACSignal *)abbreviationSignal extrapolateTargetStringBlock:(NSString *(^)(id))targetStringBlock {
	NSParameterAssert(abbreviationSignal != nil);
	return [RACSignal combineLatest:@[ self, abbreviationSignal ] reduce:^(NSArray *array, NSString *abbreviation){
		return [array sortedArrayUsingScoreForAbbreviation:abbreviation extrapolateTargetStringBlock:targetStringBlock];
	}];
}

@end
