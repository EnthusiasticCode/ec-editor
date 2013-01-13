//
//  RACSignal+ScoreForAbbreviation.m
//  ArtCode
//
//  Created by Uri Baghin on 12/01/2013.
//
//

#import "RACSignal+ScoreForAbbreviation.h"

#import "NSString+ScoreForAbbreviation.h"

static RACScheduler *scoringScheduler() {
	static RACScheduler *scoringScheduler = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    scoringScheduler = [RACScheduler scheduler];
	});
	return scoringScheduler;
}

@implementation RACSignal (ScoreForAbbreviation)

- (RACSignal *)filterArraySignalByAbbreviation:(RACSignal *)abbreviationSignal extrapolateTargetStringBlock:(NSString *(^)(id))targetStringBlock {
	NSParameterAssert(abbreviationSignal != nil);
	
	return [[[[RACSignal combineLatest:@[ self, abbreviationSignal ]] map:^(RACTuple *tuple){
		RACTupleUnpack(NSArray *array, NSString *abbreviation) = tuple;
		
		return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
			CANCELLATION_DISPOSABLE(disposable);
			
			[disposable addDisposable:[scoringScheduler() schedule:^{
				IF_CANCELLED_RETURN();
				NSMutableArray *sortedArray = [NSMutableArray arrayWithCapacity:array.count];
				
				for (id object in array) {
					IF_CANCELLED_RETURN();
					if (abbreviation.length == 0) {
						[sortedArray addObject:[RACTuple tupleWithObjects:object, nil]];
					} else {
						NSIndexSet *hitMask = nil;
						float score = [targetStringBlock ? targetStringBlock(object) : (NSString *)object scoreForAbbreviation:abbreviation hitMask:&hitMask];
						if (score > 0.0) [sortedArray addObject:[RACTuple tupleWithObjects:object, hitMask ?: RACTupleNil.tupleNil, @(score), nil]];
					}
				}
				
				[sortedArray sortUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
					IF_CANCELLED_RETURN(NSOrderedSame);
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
				
				[subscriber sendNext:sortedArray];
			}]];
			
			return disposable;
		}];
	}] switchToLatest] deliverOn:RACScheduler.currentScheduler];
}

@end
