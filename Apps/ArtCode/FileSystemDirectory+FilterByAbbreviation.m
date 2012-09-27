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

static NSArray *(^_filterByAbbreviation)(RACTuple *) = ^NSArray *(RACTuple *tuple) {
  NSArray *content = tuple.first;
  NSString *abbreviation = tuple.second;

  if (![abbreviation length]) {
    return content;
  }
  
  NSMutableArray *filteredContent = [NSMutableArray array];
  for (NSURL *childURL in content) {
    NSIndexSet *hitMask = nil;
    float score = [[childURL lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
    if (!score) {
      continue;
    }
    [childURL setAbbreviationScore:score];
    [childURL setAbbreviationHitMask:hitMask];
    [filteredContent addObject:childURL];
  }
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
  return [[self class] coordinateSubscribable:[RACSubscribable combineLatest:@[[self internalContent], abbreviationSubscribable] reduce:_filterByAbbreviation]];
}

- (id<RACSubscribable>)contentWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[self class] coordinateSubscribable:[RACSubscribable combineLatest:@[[self internalContentWithOptions:options], abbreviationSubscribable] reduce:_filterByAbbreviation]];
}

@end

static void *_NSURLAbbreviationScoreKey;
static void *_NSURLAbbreviationHitMaskKey;

@implementation NSURL (Abbreviation)

- (NSIndexSet *)abbreviationHitMask {
  return objc_getAssociatedObject(self, &_NSURLAbbreviationHitMaskKey);
}

@end

@implementation NSURL (Abbreviation_Internal)

- (void)setAbbreviationHitMask:(NSIndexSet *)hitMask {
  objc_setAssociatedObject(self, &_NSURLAbbreviationHitMaskKey, hitMask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (float)abbreviationScore {
  return [objc_getAssociatedObject(self, &_NSURLAbbreviationScoreKey) floatValue];
}

- (void)setAbbreviationScore:(float)score {
  objc_setAssociatedObject(self, &_NSURLAbbreviationScoreKey, @(score), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end