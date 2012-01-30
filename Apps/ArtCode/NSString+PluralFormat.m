//
//  NSString+FormatWithPlural.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+PluralFormat.h"

@implementation NSString (PluralFormat)

+ (NSString *)stringWithFormatForSingular:(NSString *)singularFormat plural:(NSString *)pluralFormat count:(NSUInteger)count
{
    return count == 1 ? [self stringWithFormat:singularFormat, count] : [self stringWithFormat:pluralFormat, count];
}

- (NSString *)stringByAppendingFormatForSingular:(NSString *)singularFormat plural:(NSString *)pluralFormat count:(NSUInteger)count
{
    return count == 1 ? [self stringByAppendingFormat:singularFormat, count] : [self stringByAppendingFormat:pluralFormat, count];
}

@end
