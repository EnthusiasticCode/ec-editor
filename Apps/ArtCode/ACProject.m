//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 9/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACURL.h"

@implementation ACProject

@dynamic bookmarks;

@synthesize document = _document;

- (NSURL *)ACURL
{
    return [NSURL ACURLForProjectWithName:self.name];
}

@end
