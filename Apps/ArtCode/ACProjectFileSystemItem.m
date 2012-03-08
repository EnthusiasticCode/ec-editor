//
//  ACProjectFileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem+Internal.h"

@implementation ACProjectFileSystemItem

@synthesize name = _name;

- (id)initWithName:(NSString *)name parent:(ACProjectFileSystemItem *)parent contents:(NSFileWrapper *)contents
{
    self = [super init];
    if (!self)
        return nil;
    _name = name;
    return self;
}

@end
