//
//  RACSignal+ScoreForAbbreviation.h
//  ArtCode
//
//  Created by Uri Baghin on 12/01/2013.
//
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSignal (ScoreForAbbreviation)

// Transforms a signal of arrays by filtering and sorting the contents of the
// arrays by abbreviation score.
//
// abbreviationSignal - A signal that sends the strings with which to score the
//                      objects in the arrays.
// targetStringBlock  - An optional block used to calculate strings used for
//                      scoring the objects in the array.
//
// Returns a signal of sorted arrays of triples of object, hit mask and score
// for every object that scores higher than 0.0.
- (RACSignal *)filterArraySignalByAbbreviation:(RACSignal *)abbreviationSignal extrapolateTargetStringBlock:(NSString *(^)(id element))targetStringBlock;

@end
