//
//  ACProjectFolder.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFolder+Internal.h"
#import "ACProjectFileSystemItem+Internal.h"

@interface ACProjectFolder ()
{
    NSFileWrapper *_contents;
    NSMutableArray *_children;
}
@end

@implementation ACProjectFolder

- (NSArray *)children
{
    return [_children copy];
}

- (id)initWithName:(NSString *)name parent:(ACProjectFileSystemItem *)parent contents:(NSFileWrapper *)contents
{
    self = [super initWithName:name parent:parent contents:contents];
    if (!self)
        return nil;
    _children = [[NSMutableArray alloc] init];
    return self;
}

- (NSFileWrapper *)contents
{
    if (!_contents)
    {
        _contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        _contents.preferredFilename = self.name;
    }
    return _contents;
}

- (BOOL)addNewFolderWithName:(NSString *)name error:(NSError *__autoreleasing *)error
{
    ACProjectFolder *newFolder = [[ACProjectFolder alloc] initWithName:name parent:self contents:nil];
    if ([self.contents addFileWrapper:newFolder.contents])
    {
        [_children addObject:newFolder];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)removeChild:(ACProjectFileSystemItem *)child
{
    ECASSERT([_children containsObject:child]);
    [self.contents removeFileWrapper:child.contents];
    [_children removeObject:child];
}

@end
