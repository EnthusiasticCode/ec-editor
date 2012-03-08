//
//  ACProjectFileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectFolder+Internal.h"

@implementation ACProjectFileSystemItem

@synthesize name = _name, parentFolder = _parentFolder;

- (id)initWithName:(NSString *)name parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    self = [super init];
    if (!self)
        return nil;
    _name = name;
    _parentFolder = parent;
    return self;
}

- (void)remove
{
    ECASSERT(self.parentFolder);
    [self.parentFolder removeChild:self];
}

@end
