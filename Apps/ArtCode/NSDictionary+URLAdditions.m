//
//  NSDictionary+Additions.m
//  Foundation
//
//  Created by Nicola Peduzzi on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+URLAdditions.h"
#import "NSString+URLAdditions.h"

@implementation NSDictionary (Additions)

+ (NSDictionary *)dictionaryWithURLEncodedString:(NSString *)encodedString
{
	if (!encodedString) {
		return nil;
	}
	
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	NSArray *pairs = [encodedString componentsSeparatedByString:@"&"];
	
	for (NSString *kvp in pairs)
    {
		if ([kvp length] == 0)
			continue;
		
		NSRange pos = [kvp rangeOfString:@"="];
		NSString *key = nil;
		NSString *val = nil;
		
		if (pos.location == NSNotFound)
        {
			key = [kvp stringByUnescapingFromURLQuery];
			val = @"";
		} else {
			key = [[kvp substringToIndex:pos.location] stringByUnescapingFromURLQuery];
			val = [[kvp substringFromIndex:pos.location + pos.length] stringByUnescapingFromURLQuery];
		}
		
		if (!key || !val)
			continue;
		
		[result setObject:val forKey:key];
	}
	return result;
}


- (NSString *)stringWithURLEncodedComponents
{
	NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:[self count]];
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		[arguments addObject:[NSString stringWithFormat:@"%@=%@",
							  [key stringByEscapingForURLQuery],
							  [[object description] stringByEscapingForURLQuery]]];
	}];
	
	return [arguments componentsJoinedByString:@"&"];
}


@end
