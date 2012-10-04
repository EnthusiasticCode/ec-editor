//
//  FileSystemDirectory.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem+Directory.h"
#import "FileSystemItem_Internal.h"
#import "NSString+ScoreForAbbreviation.h"

@interface FileSystemItem (Directory_Internal)

- (id<RACSubscribable>)internalChildren;

- (id<RACSubscribable>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options;

@end

@implementation FileSystemItem (Directory)

- (id<RACSubscribable>)internalChildren {
  return [self internalChildrenWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (id<RACSubscribable>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    if (!self.itemURLBacking || ![self.itemTypeBacking isEqualToString:NSURLFileResourceTypeDirectory]) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:1];
    NSMutableArray *content = [NSMutableArray array];
    for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:self.itemURLBacking includingPropertiesForKeys:nil options:options errorHandler:nil]) {
      [content addObject:childURL];
    }
    [subject sendNext:content];
    return subject;
  }];
}

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
  [filteredContent sortUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
    float score1 = [[tuple1 third] floatValue];
    float score2 = [[tuple2 third] floatValue];
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

- (id<RACSubscribable>)childrenFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[self class] coordinateSubscribable:[RACSubscribable combineLatest:@[[self internalChildren], abbreviationSubscribable] reduce:_filterAndSortByAbbreviation]];
}

- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[self class] coordinateSubscribable:[RACSubscribable combineLatest:@[[self internalChildrenWithOptions:options], abbreviationSubscribable] reduce:_filterAndSortByAbbreviation]];
}

@end
