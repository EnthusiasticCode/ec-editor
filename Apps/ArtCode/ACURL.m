//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURL.h"

@implementation NSURL (ACURL)

- (NSString *)ACProjectName
{
    ECASSERT([self.scheme isEqualToString:ACURLScheme]);
    return [self.pathComponents objectAtIndex:0];
}

+ (NSURL *)ACURLForProjectWithName:(NSString *)name
{
    ECASSERT(name);
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@:/%@", ACURLScheme, [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

+ (NSURL *)ACURLWithPath:(NSString *)path
{
    ECASSERT(path != nil);
    ECASSERT([path hasPrefix:@"/"]);
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", ACURLScheme, [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}


@end
