//
//  NSData+UTF8.m
//  CodeView
//
//  Created by Nicola Peduzzi on 17/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSData+UTF8.h"


@implementation NSData (NSData_UTF8)

- (NSUInteger)UTF8Length
{
    NSUInteger bytesCount = [self length];
    if (bytesCount == 0)
        return 0;
    
    NSUInteger length = 0;
    const char *bytes = (const char*)[self bytes];
    for (NSUInteger i = 0; i < bytesCount; ++i) 
    {
        if (bytes[i] < 0x80)
            length++;
    }
    
    return length;
}

- (NSUInteger)UTF8LineCountUsingLineDelimiter:(NSString *)lineDelimiter
{
    NSData *lineDelimiterData = [lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    if (dataLength == 0)
        return 0;
    
    NSUInteger lineCount = 1;
    NSRange searchRange = NSMakeRange(0, dataLength);
    NSRange lineRange;
    while (searchRange.length > 0 && (lineRange = [self rangeOfData:lineDelimiterData options:0 range:searchRange]).location != NSNotFound)
    {
        lineCount++;
        searchRange.location = NSMaxRange(lineRange);
        searchRange.length = dataLength - searchRange.location;
    }
    
    return lineCount;
}

@end
