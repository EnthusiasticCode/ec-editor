//
//  FileSystemDirectory+FilterByAbbreviation.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemDirectory+FilterByAbbreviation.h"
#import "FileSystemDirectory_Internal.h"
#import "FileSystemItem_Internal.h"
#import "NSString+ScoreForAbbreviation.h"

@interface NSURL (Abbreviation_Internal)

- (void)setAbbreviationHitMask:(NSIndexSet *)hitMask;
- (float)abbreviationScore;
- (void)setAbbreviationScore:(float)score;

@end

@implementation FileSystemDirectory (FilterByAbbreviation)

static NSArray *(^_filterAndSortByAbbreviation)(RACTuple *) = ^NSArray *(RACTuple *tuple) {
  NSArray *content = tuple.first;
  NSString *abbreviation = tuple.second;
  
  // No abbreviation, no need to filter
  if (![abbreviation length]) {
    return [[[content rac_toSubscribable] select:^id(NSURL *url) {
      return [RACTuple tupleWithObjectsFromArray:@[url, [RACTupleNil tupleNil]]];
    }] toArray];
  }
  
  // Filter the content
  NSMutableArray *filteredContent = [[[[[content rac_toSubscribable] select:^id(NSURL *url) {
    NSIndexSet *hitMask = nil;
    float score = [[url lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
    return [RACTuple tupleWithObjectsFromArray:@[url, hitMask ? : [RACTupleNil tupleNil], @(score)]];
  }] where:^BOOL(RACTuple *item) {
    return [item.third floatValue] > 0;
  }] toArray] mutableCopy];

  // Sort the filtered content
  [filteredContent sortUsingComparator:^NSComparisonResult(NSURL *url1, NSURL *url2) {
    float score1 = [url1 abbreviationScore];
    float score2 = [url2 abbreviationScore];
    if (score1 < score2) {
      return NSOrderedAscending;
    } else if (score1 > score2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
  return filteredContent;
};

- (id<RACSubscribable>)contentFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[self class] coordinateSubscribable:[RACSubscribable combineLatest:@[[self internalContent], abbreviationSubscribable] reduce:_filterAndSortByAbbreviation]];
}

- (id<RACSubscribable>)contentWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[self class] coordinateSubscribable:[RACSubscribable combineLatest:@[[self internalContentWithOptions:options], abbreviationSubscribable] reduce:_filterAndSortByAbbreviation]];
}

@end
