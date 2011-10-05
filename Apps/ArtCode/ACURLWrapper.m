//
//  ACURLWrapper.m
//  ArtCode
//
//  Created by Uri Baghin on 10/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURLWrapper.h"
#import "ACApplication.h"

@implementation ACURLWrapper

@dynamic application;

- (NSURL *)URL
{
    NSURL *URL = [NSURL URLWithString:[self primitiveValueForKey:@"URL"]];
    if ([URL scheme])
        return URL;
    return [[self.application projectsDirectory] URLByAppendingPathComponent:[self primitiveValueForKey:@"URL"]];
}

- (void)setURL:(NSURL *)URL
{
    [self willChangeValueForKey:@"URL"];
    NSString *string = [self.application pathRelativeToProjectsDirectory:URL];
    if (!string)
        string = [URL absoluteString];
    [self setPrimitiveValue:string forKey:@"URL"];
    [self didChangeValueForKey:@"URL"];
}

@end