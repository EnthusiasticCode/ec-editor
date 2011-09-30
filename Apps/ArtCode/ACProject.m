//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 9/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACProjectListItem.h"
#import "ACURL.h"

@implementation ACProject

@dynamic bookmarks;

@synthesize projectListItem = _projectListItem;

- (NSURL *)ACURL
{
    return self.projectListItem.projectURL;
}

@end
