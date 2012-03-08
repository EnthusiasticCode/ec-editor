//
//  ACProjectFolder.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFile.h"
#import "ACProjectFolder+Internal.h"
#import "ACProjectFileSystemItem+Internal.h"

#import "ACProject.h"


@interface ACProjectFolder ()
{
    NSMutableArray *_children;
}
@end

@implementation ACProjectFolder

- (NSArray *)children
{
    return [_children copy];
}

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent contents:contents];
    if (!self)
        return nil;
    _children = [[NSMutableArray alloc] init];
    return self;
}

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    contents.preferredFilename = self.name;
    return contents;
}

- (BOOL)addNewFolderWithName:(NSString *)name contents:(NSFileWrapper *)contents plist:(NSDictionary *)plist error:(NSError *__autoreleasing *)error
{
    if (!contents)
        contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    contents.preferredFilename = name;
    ACProjectFolder *newFolder = [[ACProjectFolder alloc] initWithProject:self.project propertyListDictionary:plist parent:self contents:contents];
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

- (BOOL)addNewFileWithName:(NSString *)name contents:(NSFileWrapper *)contents plist:(NSDictionary *)plist error:(NSError *__autoreleasing *)error
{
    if (!contents)
        contents = [[NSFileWrapper alloc] initRegularFileWithContents:nil];
    contents.preferredFilename = name;
    ACProjectFile *newFile = [[ACProjectFile alloc] initWithProject:self.project propertyListDictionary:plist parent:self contents:contents];
    if ([self.contents addFileWrapper:newFile.contents])
    {
        [_children addObject:newFile];
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

#pragma mark - Item methods

- (NSURL *)URL
{
    if (self.parentFolder == nil)
        return [self.project.fileURL URLByAppendingPathComponent:self.name isDirectory:YES];
    return [self.parentFolder.URL URLByAppendingPathComponent:self.name isDirectory:YES];
}

- (ACProjectItemType)type
{
    return ACPFolder;
}

@end
