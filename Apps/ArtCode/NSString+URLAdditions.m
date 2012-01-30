//
//  NSString+URLAdditions.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+URLAdditions.h"

@implementation NSString (URLAdditions)

- (NSString *)stringByEscapingForURLQuery
{
	NSString *result = self;
    
	static CFStringRef leaveAlone = CFSTR(" ");
	static CFStringRef toEscape = CFSTR("\n\r:/=,!$&'()*+;[]@#?%");
    
	CFStringRef escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, leaveAlone, toEscape, kCFStringEncodingUTF8);
    
	if (escapedStr)
    {
		NSMutableString *mutable = [NSMutableString stringWithString:(__bridge NSString *)escapedStr];
		CFRelease(escapedStr);
        
		[mutable replaceOccurrencesOfString:@" " withString:@"+" options:0 range:NSMakeRange(0, [mutable length])];
		result = mutable;
	}
	return result;  
}


- (NSString *)stringByUnescapingFromURLQuery
{
	NSString *deplussed = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return [deplussed stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
