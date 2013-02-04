//
//  NSString+TextMateScopeSelectorMatching.m
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+TextMateScopeSelectorMatching.h"


@interface NSString (TextMateScopeSelectorMatchingInternal)

// Return a number indicating how much a scope selector array matches the search.
// A scope selector array is an array of strings defining a context of scopes where
// a scope must be child of the previous scope in the array.
- (float)_scoreQueryScopeArray:(NSArray *)query forSearchScopeArray:(NSArray *)search;

// Returns a number indicating how much the receiver matches the search scope selector.
// A scope selector reference is a string containing a single scope context (ie: scopes divided by spaces).
- (float)_scoreForSearchScope:(NSString *)search;

@end

@implementation NSString (TextMateScopeSelectorMatching)

// Reference implementation: https://github.com/cehoffman/textpow/blob/master/lib/textpow/score_manager.rb

- (float)scoreForScopeSelector:(NSString *)scopeSelector
{
  // Caches a scope identifier to a dictionary of scope selector references to scores.
	
	// Analyzer will complain if you synchronize on a nil object, so initialize it to something non-nil
  static NSMutableDictionary *systemScopesScoreCache = (NSMutableDictionary *)@"";
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    systemScopesScoreCache = [NSMutableDictionary dictionary];
  });
	
  @synchronized(systemScopesScoreCache) {
    NSMutableDictionary *scopeToScore = systemScopesScoreCache[scopeSelector];
    NSNumber *cachedScore = scopeToScore[self];
    if (cachedScore)
      return [cachedScore floatValue];
  }
  
  // Compute value
  static NSCharacterSet *spaceCharacterSet = nil;
  static dispatch_once_t onceToken2;
  dispatch_once(&onceToken2, ^{
    spaceCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
  });
  
  float score = 0;
  for (NSString *searchScope in [scopeSelector componentsSeparatedByString:@","]) {
    NSArray *searchScopeComponents = [[searchScope stringByTrimmingCharactersInSet:spaceCharacterSet] componentsSeparatedByString:@" - "];
    if (searchScopeComponents.count == 1) {
      score = MAX(score, [self _scoreForSearchScope:searchScopeComponents[0]]);
    } else {
      __block BOOL exclude = NO;
      [searchScopeComponents enumerateObjectsUsingBlock:^(NSString *excludeScope, NSUInteger idx, BOOL *stop) {
        if (idx && [self _scoreForSearchScope:excludeScope] > 0) {
          exclude = YES;
          *stop = YES;
        }
      }];
      if (exclude) continue;
      score = MAX(score, [self _scoreForSearchScope:searchScopeComponents[0]]);
    }
  }
  
  @synchronized(systemScopesScoreCache) {
    // Store in cache
    NSMutableDictionary *scopeToScore = systemScopesScoreCache[scopeSelector];
    if (!scopeToScore) {
      scopeToScore = [NSMutableDictionary dictionary];
      systemScopesScoreCache[scopeSelector] = scopeToScore;
    }
    scopeToScore[self] = @(score);
  }
  return score;
}

@end

@implementation NSString (TextMateScopeSelectorMatchingInternal)

- (float)_scoreForSearchScope:(NSString *)search {
  static NSCharacterSet *trimCharacterSet = nil; if (!trimCharacterSet) trimCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" ()"];
  float score = 0;
  for (NSString *singleSearch in [search componentsSeparatedByString:@"|"]) {
    score = MAX(score, [self _scoreQueryScopeArray:[self componentsSeparatedByString:@" "] forSearchScopeArray:[[singleSearch stringByTrimmingCharactersInSet:trimCharacterSet] componentsSeparatedByString:@" "]]);
  }
  return score;
}

#define POINT_DEPTH    4.0f
#define NESTING_DEPTH  30.0f
#define BASE           16.0f

- (float)_scoreQueryScopeArray:(NSArray *)query forSearchScopeArray:(NSArray *)search {
  static float start_value = 0; if (!start_value) start_value = powf(2, (POINT_DEPTH * NESTING_DEPTH));
  static NSRegularExpression *dotRegExp = nil; if (!dotRegExp) dotRegExp = [NSRegularExpression regularExpressionWithPattern:@"." options:NSRegularExpressionIgnoreMetacharacters error:NULL];
  
  float multiplier = start_value;
  float result = 0;
  // The scopes will be enumerated from the most specific up.
  NSEnumerator *searchEnumerator = [search reverseObjectEnumerator];
  NSString *currentSearch = [searchEnumerator nextObject];
  for (NSString *currentQuery in [query reverseObjectEnumerator]) {
    if (!currentSearch) break;
    // In case the current query scope starts with the search scope a score can be computed
    if ([currentQuery hasPrefix:currentSearch]) {
      result += (BASE - [dotRegExp numberOfMatchesInString:currentQuery options:0 range:NSMakeRange(0, [currentQuery length])] + [dotRegExp numberOfMatchesInString:currentSearch options:0 range:NSMakeRange(0, [currentSearch length])]) * multiplier;
      currentSearch = [searchEnumerator nextObject];
    }
    multiplier /= BASE;
  }
  // Return the result only if the whole search array has been evaluated
  ASSERT(result < INFINITY);
  return currentSearch == nil ? result : 0;
}

@end
