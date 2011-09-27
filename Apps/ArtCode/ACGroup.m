//
//  ACGroup.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACGroup.h"

@implementation ACGroup

@dynamic name;

- (NSURL *)fileURL
{
    return self.parent.fileURL;
}

+ (NSSet *)keyPathsForValuesAffectingName
{
    return [NSSet setWithObject:@"parent.fileURL"];
}

@end
