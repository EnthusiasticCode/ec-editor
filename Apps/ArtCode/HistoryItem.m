//
//  HistoryItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HistoryItem.h"
#import "ArtCodeProject.h"
#import "ArtCodeTab.h"


@implementation HistoryItem

@dynamic tab;

- (NSURL *)URL
{
    NSURL *URL = [NSURL URLWithString:[self primitiveValueForKey:@"URL"]];
    if ([URL scheme])
        return URL;
    return [[ArtCodeProject projectsDirectory] URLByAppendingPathComponent:[self primitiveValueForKey:@"URL"]];
}

- (void)setURL:(NSURL *)URL
{
    [self willChangeValueForKey:@"URL"];
    NSString *string = [ArtCodeProject pathRelativeToProjectsDirectory:URL];
    if (!string)
        string = [URL absoluteString];
    ECASSERT(string);
    [self setPrimitiveValue:string forKey:@"URL"];
    [self didChangeValueForKey:@"URL"];
}

- (Application *)application
{
    return self.tab.application;
}

+ (NSSet *)keyPathsForValuesAffectingApplication
{
    return [NSSet setWithObject:@"tab.application"];
}

@end
