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


@implementation ACProjectFileSystemItem {
    NSFileWrapper *_contents;
}

@synthesize name = _name, parentFolder = _parentFolder;

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    if (!project || !contents || !contents.preferredFilename)
        return nil;
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    _contents = contents;
    _name = contents.preferredFilename;
    _parentFolder = parent;
    return self;
}

- (NSFileWrapper *)contents
{
    if (!_contents)
        _contents = [self defaultContents];
    return _contents;
}

- (NSFileWrapper *)defaultContents
{
    return [NSFileWrapper new];
}

#pragma mark - Item methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    return [self initWithProject:project propertyListDictionary:plistDictionary parent:nil contents:nil];
}

- (NSDictionary *)propertyListDictionary
{
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:self.name forKey:@"name"];
    return plist;
}

- (void)remove
{
    ECASSERT(self.parentFolder);
    [self.parentFolder didRemoveChild:self];
    [super remove];
}

@end
