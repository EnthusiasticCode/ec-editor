//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"


@implementation ACProject

@synthesize URL = _URL;
@synthesize fileURL = _fileURL;

- (NSString *)name
{
    return [[self.URL lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)setName:(NSString *)name
{
    ECASSERT(name);
    self.URL = [[self.URL URLByDeletingLastPathComponent] URLByAppendingPathComponent:name];
}

+ (NSSet *)keyPathsForValuesAffectingName
{
    return [NSSet setWithObject:@"URL"];
}

+ (NSSet *)keyPathsForValuesAffectingURL {
    return [NSSet set];
}

+ (NSSet *)keyPathsForValuesAffectingFileURL {
    return [NSSet set];
}

@end
