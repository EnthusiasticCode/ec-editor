//
//  RangeSet.h
//  ArtCode
//
//  Created by Uri Baghin on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RangeSet : NSObject <NSCopying, NSMutableCopying>

- (id)initWithRangeSet:(RangeSet *)rangeSet;

- (NSUInteger)count;

- (NSRange)rangeAtIndex:(NSUInteger)index;

- (void)enumerateRangesWithBlock:(void(^)(NSRange range, NSUInteger index, BOOL *stop))block;

@end

@interface MutableRangeSet : RangeSet

- (void)addRange:(NSRange)range;
- (void)removeRange:(NSRange)range;

- (void)insertRange:(NSRange)range;
- (void)deleteRange:(NSRange)range;
- (void)replaceRange:(NSRange)oldRange withRange:(NSRange)newRange;

@end