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

#import "NSString+Utilities.h"

static NSString * const _childrenKey = @"children";

@interface ACProjectFolder ()
- (void)_setFileWrapper:(NSFileWrapper *)fileWrapper andPlist:(NSDictionary *)plist;
- (void)_addChildFileSystemItem:(ACProjectFileSystemItem *)item;
@end

#pragma mark -

@interface ACProject (Folders)

- (void)addFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem withBlock:(void(^)(void))block;
- (void)removeFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem withBlock:(void(^)(void))block;

@end

#pragma mark -

@implementation ACProjectFolder {
  /// Dictionary of item name to ACProjectFileSystemItem.
  @package
  NSMutableDictionary *_children;
}

#pragma mark - ACProjectItem

- (ACProjectItemType)type {
  return ACPFolder;
}

#pragma mark - ACProjectItem Internal

- (NSDictionary *)propertyListDictionary {
  NSMutableDictionary *plist = super.propertyListDictionary.mutableCopy;
  NSMutableDictionary *children = [NSMutableDictionary.alloc initWithCapacity:_children.count];
  [_children enumerateKeysAndObjectsUsingBlock:^(NSString *key, ACProjectFileSystemItem *item, BOOL *stop) {
    [children setObject:item.propertyListDictionary forKey:key];
  }];
  [plist setObject:children forKey:_childrenKey];
  return plist;
}

- (void)prepareForRemoval {
  for (ACProjectFileSystemItem *item in _children.allValues) {
    [self removeChildItem:item];
  }
}

#pragma mark - ACProjectFileSystemItem Internal

- (NSFileWrapper *)fileWrapper {
  NSFileWrapper *fileWrapper = [NSFileWrapper.alloc initDirectoryWithFileWrappers:nil];
  fileWrapper.preferredFilename = self.name;
  for (ACProjectFileSystemItem *item in _children.allValues) {
    [fileWrapper addFileWrapper:item.fileWrapper];
  }
  return fileWrapper;
}

- (void)setFileWrapper:(NSFileWrapper *)fileWrapper {
  [self _setFileWrapper:fileWrapper andPlist:nil];
}

- (id)initWithProject:(ACProject *)project fileWrapper:(NSFileWrapper *)fileWrapper propertyListDictionary:(NSDictionary *)plistDictionary {
  self = [super initWithProject:project fileWrapper:fileWrapper propertyListDictionary:plistDictionary];
  if (!self) {
    return nil;
  }

  _children = NSMutableDictionary.alloc.init;
  
  [self _setFileWrapper:fileWrapper andPlist:plistDictionary];
  
  return self;
}

#pragma mark - Accessing folder content

- (NSArray *)children {
  return _children.allValues;
}

- (ACProjectFileSystemItem *)childWithName:(NSString *)name {
  return [_children objectForKey:name];
}

#pragma mark - Creating and deleting folders and files

- (ACProjectFolder *)newChildFolderWithName:(NSString *)name {
  if ([_children objectForKey:name]) {
    return nil;
  }
  NSFileWrapper *fileWrapper = [NSFileWrapper.alloc initDirectoryWithFileWrappers:nil];
  fileWrapper.preferredFilename = name;
  ACProjectFolder *folder = [ACProjectFolder.alloc initWithProject:self.project fileWrapper:fileWrapper propertyListDictionary:nil];
  [self _addChildFileSystemItem:folder];
  return folder;
}

- (ACProjectFile *)newChildFileWithName:(NSString *)name {
  if ([_children objectForKey:name]) {
    return nil;
  }
  NSFileWrapper *fileWrapper = [NSFileWrapper.alloc initRegularFileWithContents:nil];
  fileWrapper.preferredFilename = name;
  ACProjectFile *file = [ACProjectFile.alloc initWithProject:self.project fileWrapper:fileWrapper propertyListDictionary:nil];
  [self _addChildFileSystemItem:file];
  return file;
}

- (void)removeChildItem:(ACProjectFileSystemItem *)childItem {
  if ([_children objectForKey:childItem.name] != childItem) {
    return;
  }
  [self willChangeValueForKey:@"children"];
  [self.project removeFileSystemItem:childItem withBlock:^{
    [childItem prepareForRemoval];
    childItem.parentFolder = nil;
    [_children removeObjectForKey:childItem.name];
    [self.project updateChangeCount:UIDocumentChangeDone];
  }];
  [self didChangeValueForKey:@"children"];
}

#pragma mark - Private Methods

- (void)_setFileWrapper:(NSFileWrapper *)fileWrapper andPlist:(NSDictionary *)plist {
  NSDictionary *childrenPlist = [plist objectForKey:_childrenKey];
  
  // Get missing files
  NSMutableArray *itemsToRemove = NSMutableArray.alloc.init;
  for (ACProjectFileSystemItem *item in _children.allValues) {
    if (![fileWrapper.fileWrappers objectForKey:item.name]) {
      [itemsToRemove addObject:item];
    }
  }
  
  // Get added files
  NSMutableArray *itemsToAdd = NSMutableArray.alloc.init;
  for (NSFileWrapper *childWrapper in fileWrapper.fileWrappers.allValues) {
    NSString *childName = childWrapper.preferredFilename;
    if ([_children objectForKey:childName]) {
      continue;
    }
    Class childClass = nil;
    if (childWrapper.isDirectory) {
      childClass = ACProjectFolder.class;
    } else if (childWrapper.isRegularFile) {
      childClass = ACProjectFile.class;
    }
    if (!childClass) {
      continue;
    }
    [itemsToAdd addObject:[childClass.alloc initWithProject:self.project fileWrapper:childWrapper propertyListDictionary:[childrenPlist objectForKey:childName]]];
  }
  
  // Do the update
  for (ACProjectFileSystemItem *item in itemsToRemove) {
    [self removeChildItem:item];
  }
  for (ACProjectFileSystemItem *item in itemsToAdd) {
    [self _addChildFileSystemItem:item];
  }
}

- (void)_addChildFileSystemItem:(ACProjectFileSystemItem *)item {
  [self willChangeValueForKey:@"children"];
  [self.project addFileSystemItem:item withBlock:^{
    item.parentFolder = self;
    [_children setObject:item forKey:item.name];
    [self.project updateChangeCount:UIDocumentChangeDone];
  }];
  [self didChangeValueForKey:@"children"];
}

@end

#pragma mark -

@implementation ACProjectFileSystemItem (RenamingMovingAndCopying)

- (void)moveToFolder:(ACProjectFolder *)newParent renameTo:(NSString *)newName {
  ACProjectFolder *oldParent = self.parentFolder;
  if (newParent != oldParent) {
    [oldParent willChangeValueForKey:@"children"];
    [newParent willChangeValueForKey:@"children"];
  }
  [oldParent->_children removeObjectForKey:self.name];
  if (newName) {
    self.name = newName;
  }
  self.parentFolder = newParent;
  [newParent->_children setObject:self forKey:self.name];
  [self.project updateChangeCount:UIDocumentChangeDone];
  if (newParent != oldParent) {
    [oldParent didChangeValueForKey:@"children"];
    [newParent didChangeValueForKey:@"children"];
  }
}

- (ACProjectFileSystemItem *)copyToFolder:(ACProjectFolder *)copyParent renameTo:(NSString *)newName {
  [copyParent willChangeValueForKey:@"children"];
  ACProjectFileSystemItem *copy = [self.class.alloc initWithProject:self.project fileWrapper:self.fileWrapper propertyListDictionary:nil];
  if (newName) {
    copy.name = newName;
  }
  [copyParent _addChildFileSystemItem:copy];
  [copyParent didChangeValueForKey:@"children"];
  return copy;
}

@end
