//
//  ACProjectFolder.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFolder.h"
#import "ACProjectItem+Internal.h"
#import "ACProjectFileSystemItem+Internal.h"

#import "ACProjectFile.h"
#import "ACProject.h"

static NSString * const _childrenKey = @"children";

@interface ACProject (Folders)

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;

@end

@implementation ACProjectFolder {
    NSMutableDictionary *_children;
}

#pragma mark - Properties

- (NSArray *)children
{
    return _children.allValues;
}

#pragma mark - Initialization and serialization

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent contents:(NSFileWrapper *)contents
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent contents:contents];
    if (!self)
        return nil;
    _children = [[NSMutableDictionary alloc] initWithCapacity:contents.fileWrappers.count];
    NSDictionary *childrenPlists = [plistDictionary objectForKey:_childrenKey];
    [contents.fileWrappers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSFileWrapper *fileWrapper, BOOL *stop) {
        ECASSERT(fileWrapper.isRegularFile || fileWrapper.isDirectory);
        ACProjectFileSystemItem *item = [[(fileWrapper.isDirectory ? [ACProjectFolder class] : [ACProjectFile class]) alloc] initWithProject:project propertyListDictionary:[childrenPlists objectForKey:key] parent:self contents:fileWrapper];
        [_children setObject:item forKey:key];
        [project didAddFileSystemItem:item];
    }];
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    NSMutableDictionary *children = [[NSMutableDictionary alloc] initWithCapacity:_children.count];
    [_children enumerateKeysAndObjectsUsingBlock:^(NSString *key, ACProjectFileSystemItem *item, BOOL *stop) {
        [children setObject:item.propertyListDictionary forKey:key];
    }];
    [plist setObject:children forKey:_childrenKey];
    return plist;
}

#pragma mark - Contents

- (BOOL)addNewFolderWithName:(NSString *)name contents:(NSFileWrapper *)contents plist:(NSDictionary *)plist error:(NSError *__autoreleasing *)error
{
    if (!contents)
        contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    contents.preferredFilename = name;
    ACProjectFolder *newFolder = [[ACProjectFolder alloc] initWithProject:self.project propertyListDictionary:plist parent:self contents:contents];
    NSString *key = [self.contents addFileWrapper:newFolder.contents];
    if (key)
    {
        [_children setObject:newFolder forKey:key];
        [self.project didAddFileSystemItem:newFolder];
        [self.project updateChangeCount:UIDocumentChangeDone];
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
    NSString *key = [self.contents addFileWrapper:newFile.contents];
    if (key)
    {
        [_children setObject:newFile forKey:key];
        [self.project didAddFileSystemItem:newFile];
        [self.project updateChangeCount:UIDocumentChangeDone];
        return YES;
    }
    else
    {
        return NO;
    }
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

- (void)remove
{
    for (ACProjectFileSystemItem *item in _children.allValues)
        [item remove];
    [super remove];
}

#pragma mark - Internal Methods

- (NSFileWrapper *)defaultContents
{
    NSFileWrapper *contents = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    contents.preferredFilename = self.name;
    return contents;
}

- (void)didRemoveChild:(ACProjectFileSystemItem *)child
{
    ECASSERT([_children.allValues containsObject:child]);
    NSString *key = [self.contents keyForFileWrapper:child.contents];
    ECASSERT(key);
    [self.contents removeFileWrapper:child.contents];
    [_children removeObjectForKey:key];
}

@end
