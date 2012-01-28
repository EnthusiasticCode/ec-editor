//
//  NSString+AppStyle.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+AppStyle.h"

@implementation NSString (AppStyle)

- (NSString *)prettyPath
{
    return [[self stringByReplacingOccurrencesOfString:@".weakpkg" withString:@""] stringByReplacingOccurrencesOfString:@"/" withString:@" ▸ "];
}

@end
