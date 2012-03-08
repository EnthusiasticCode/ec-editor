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

@property (nonatomic, strong, readonly) NSMutableDictionary *_descendants;

@end

@implementation ACProjectFolder {
    NSMutableArray *_children;
}

#pragma mark - Properties

@synthesize _descendants;

- (NSArray *)children
{
    return [_children copy];
}

- (NSArray *)descendants
{
    return [[self _descendants] allValues];
}

- (NSMutableDictionary *)_descendants
{
    if (!_descendants)
    {
        _descendants = [NSMutableDictionary dictionaryWithCapacity:[_children count]];
        for (ACProjectFileSystemItem *item in _children)
        {
            [_descendants setObject:item forKey:item.UUID];
            if ([item isMemberOfClass:[ACProjectFolder class]])
                [_descendants addEntriesFromDictionary:[(ACProjectFolder *)item _descendants]];
        }
    }
    return _descendants;
}

#pragma mark - Initialization

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent contents:contents];
    if (!self)
        return nil;
    _children = [NSMutableArray new];
    return self;
}

#pragma mark - Contents

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
        // Clear descendants instead of making the new folder calculate its own if not needed
        _descendants = nil;
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
        // If descendants are populated, add the new file
        if (_descendants)
            [_descendants setObject:newFile forKey:newFile.UUID];
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
