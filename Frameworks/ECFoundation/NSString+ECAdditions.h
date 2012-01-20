//
//  NSString+ECAdditions.h
//  ECFoundation
//
//  Created by Uri Baghin on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ECAdditions)

/// Returns the Quicksilver score of the receiver
/// The return value is between 0 and 1, depending on how well the given abbreviation matches the receiver.
/// If a hitmask is passed by reference, on return it will return the indexes of characters in the receiver that match the abbreviation.
- (float)scoreForAbbreviation:(NSString *)abbreviation;
- (float)scoreForAbbreviation:(NSString *)abbreviation hitMask:(NSIndexSet **)mask;
- (float)scoreForAbbreviation:(NSString *)abbreviation inRange:(NSRange)searchRange fromRange:(NSRange)abbreviationRange hitMask:(NSIndexSet **)mask;

- (NSString *)stringByEscapingForURLQuery;
- (NSString *)stringByUnescapingFromURLQuery;

/// Returna a new string based on the count. The count is passed to the format string.
+ (NSString *)stringWithFormatForSingular:(NSString *)singularFormat plural:(NSString *)pluralFormat count:(NSUInteger)count;
- (NSString *)stringByAppendingFormatForSingular:(NSString *)singularFormat plural:(NSString *)pluralFormat count:(NSUInteger)count;

@end
