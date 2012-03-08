//
//  ACProjectFileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectFolder+Internal.h"
#import "ACProjectItem+Internal.h"

@implementation ACProjectFileSystemItem

@synthesize name = _name, parentFolder = _parentFolder;

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    ECASSERT(project && contents && contents.preferredFilename);
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    _name = contents.preferredFilename;
    _parentFolder = parent;
    return self;
}

- (void)remove
{
    ECASSERT(self.parentFolder);
    [self.parentFolder removeChild:self];
}

@end
