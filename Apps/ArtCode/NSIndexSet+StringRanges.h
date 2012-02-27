//
//  NSIndexSet+StringRanges.h
//  ArtCode
//
//  Created by Uri Baghin on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// A category to assist in using NSIndexSet to track subranges in a string
@interface NSIndexSet (StringRanges)

- (NSRange)firstRange;

@end

@interface NSMutableIndexSet (StringRanges)

- (void)insertIndexesInRange:(NSRange)range;
- (void)deleteIndexesInRange:(NSRange)range;
- (void)replaceIndexesInRange:(NSRange)oldRange withIndexesInRange:(NSRange)newRange;

- (void)shiftIndexesByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange;

@end
