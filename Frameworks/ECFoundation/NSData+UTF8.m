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
    char c;
    for (NSUInteger i = 0; i < bytesCount; ++i) 
    {
        c = bytes[i];
        while ((c & 0x80) && (c & 0x40)) 
        {
            ++i;
            c <<= 1;
        }
        ++length;
    }
    
    return length;
}

@end
