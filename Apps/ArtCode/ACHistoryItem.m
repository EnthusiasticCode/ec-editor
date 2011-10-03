//
//  ACHistoryItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACHistoryItem.h"
#import "ACTab.h"


@implementation ACHistoryItem

@dynamic tab;

- (ACApplication *)application
{
    return self.tab.application;
}

+ (NSSet *)keyPathsForValuesAffectingApplication
{
    return [NSSet setWithObject:@"tab.application"];
}

@end
