//
//  NSString+Additions.m
//  Foundation
//
//  Created by Uri Baghin on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+ScoreForAbbreviation.h"

@implementation NSString (ScoreForAbbreviation)

- (float)scoreForAbbreviation:(NSString *)abbreviation
{
	return [self scoreForAbbreviation:abbreviation hitMask:nil];
}
- (float)scoreForAbbreviation:(NSString *)abbreviation hitMask:(NSIndexSet **)mask
{
	return [self scoreForAbbreviation:abbreviation inRange:NSMakeRange(0, [self length]) fromRange:NSMakeRange(0, [abbreviation length]) hitMask:mask];
}

- (float)scoreForAbbreviation:(NSString *)abbreviation inRange:(NSRange)searchRange fromRange:(NSRange)abbreviationRange hitMask:(NSIndexSet **)mask
{
  if (![abbreviation length])
    return 0.0;
	float score, remainingScore;
	int i, j;
	NSRange matchedRange, remainingSearchRange;
	if (!abbreviationRange.length)
    return 0.9; //deduct some points for all remaining letters
	if (abbreviationRange.length>searchRange.length)
    return 0.0;
	for (i = abbreviationRange.length; i>0; i--)
  { //Search for steadily smaller portions of the abbreviation
		matchedRange = [self rangeOfString:[abbreviation substringWithRange:NSMakeRange(abbreviationRange.location, i)] options:NSCaseInsensitiveSearch range:searchRange];
    
		if (matchedRange.location == NSNotFound || matchedRange.location+abbreviationRange.length>NSMaxRange(searchRange))
      continue;
    
		if (mask)
    {
      if (!*mask)
        *mask = [NSMutableIndexSet indexSet];
      [(NSMutableIndexSet *)*mask addIndexesInRange:matchedRange];
    }
    
		remainingSearchRange.location = NSMaxRange(matchedRange);
		remainingSearchRange.length = NSMaxRange(searchRange) -remainingSearchRange.location;
    
		// Search what is left of the string with the rest of the abbreviation
		remainingScore = [self scoreForAbbreviation:abbreviation inRange:remainingSearchRange fromRange:NSMakeRange(abbreviationRange.location+i, abbreviationRange.length-i) hitMask:mask];
		if (remainingScore)
    {
			score = remainingSearchRange.location-searchRange.location;
			// ignore skipped characters if is first letter of a word
			if (matchedRange.location>searchRange.location)
      {//if some letters were skipped
				if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:matchedRange.location-1]])
        {
					for (j = matchedRange.location-2; j >= (int) searchRange.location; j--)
          {
						if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:j]])
              score--;
						else
              score -= 0.15;
					}
				}
        else if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[self characterAtIndex:matchedRange.location]])
        {
					for (j = matchedRange.location-1; j >= (int) searchRange.location; j--)
          {
						if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[self characterAtIndex:j]])
							score--;
						else
							score -= 0.15;
					}
				}
        else
        {
					score -= matchedRange.location-searchRange.location;
				}
			}
			score += remainingScore*remainingSearchRange.length;
			score /= searchRange.length;
			return score;
		}
	}
	return 0;
}

@end
