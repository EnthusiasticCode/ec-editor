//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACURL.h"

@implementation ACProject

@dynamic application;

- (NSURL *)ACURL
{
    return [NSURL ACURLForProjectWithName:self.name];
}

@end
