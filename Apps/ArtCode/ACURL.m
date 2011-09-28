//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURL.h"

static NSString * const ACURLScheme = @"artcode";

@implementation NSURL (ACURL)

- (BOOL)isACURL
{
    return [self.scheme isEqualToString:ACURLScheme];
}

@end
