//
//  ProjectListItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectListItem.h"
#import "ACApplication.h"
#import "ACURL.h"

@implementation ACProjectListItem

@dynamic tag;
@dynamic application;

- (NSURL *)projectURL
{
    return [NSURL URLWithString:[self primitiveValueForKey:@"projectURL"]];
}

- (void)setProjectURL:(NSURL *)projectURL
{
    [self willChangeValueForKey:@"projectURL"];
    [self setPrimitiveValue:[projectURL absoluteString] forKey:@"projectURL"];
    [self didChangeValueForKey:@"projectURL"];
}

- (NSString *)name
{
    return [self.projectURL ACObjectName];
}

+ (NSSet *)keyPathsForValuesAffectingName
{
    return [NSSet setWithObject:@"projectURL"];
}

@end
