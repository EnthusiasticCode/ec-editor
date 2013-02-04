//
//  NSString+FormatWithPlural.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (PluralFormat)

// Returna a new string based on the count. The count is passed to the format string.
+ (NSString *)stringWithFormatForSingular:(NSString *)singularFormat plural:(NSString *)pluralFormat count:(NSUInteger)count;
- (NSString *)stringByAppendingFormatForSingular:(NSString *)singularFormat plural:(NSString *)pluralFormat count:(NSUInteger)count;

@end
