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

@interface ACProject (Folders)

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;

@end

#pragma mark -

@interface ACProjectFolder ()

- (void)_addNewChildItemWithClass:(Class)childClass name:(NSString *)name originalURL:(NSURL *)originalURL completionHandler:(void (^)(ACProjectFileSystemItem *item, NSError *error))completionHandler;

- (ACProjectFileSystemItem *)_addExistingItem:(ACProjectFileSystemItem *)item renameTo:(NSString *)newName error:(out NSError **)error;

- (ACProjectFileSystemItem *)_addCopyOfExistingItem:(ACProjectFileSystemItem *)item renameIfNeeded:(BOOL)renameIfNeeded error:(out NSError **)error;

- (void)_didAddChild:(ACProjectFileSystemItem *)child;

@end

#pragma mark -

@implementation ACProjectFolder {
  /// Dictionary of item name to ACProjectFileSystemItem.
  NSMutableDictionary *_children;
}

#pragma mark - ACProjectItem

- (ACProjectItemType)type {
  return ACPFolder;
}

#pragma mark - ACProjectItem Internal

- (NSDictionary *)propertyListDictionary {
  NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
  NSMutableDictionary *children = [[NSMutableDictionary alloc] initWithCapacity:_children.count];
  [_children enumerateKeysAndObjectsUsingBlock:^(NSString *key, ACProjectFileSystemItem *item, BOOL *stop) {
    [children setObject:item.propertyListDictionary forKey:key];
  }];
  [plist setObject:children forKey:_childrenKey];
  return plist;
}

- (void)setPropertyListDictionary:(NSDictionary *)propertyListDictionary {
  [super setPropertyListDictionary:propertyListDictionary];
  NSDictionary *childrenPlists = [propertyListDictionary objectForKey:_childrenKey];
  for (ACProjectFileSystemItem *child in _children.allValues) {
    [child setPropertyListDictionary:[childrenPlists objectForKey:child.name]];
  }
}

#pragma mark - ACProjectFileSystemItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent name:(NSString *)name {
  self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent name:name];
  if (!self) {
    return nil;
  }
  
  _children = NSMutableDictionary.alloc.init;
  
  if (![self readFromURL:self.fileURL error:NULL]) {
    return nil;
  }
  
  [self setPropertyListDictionary:plistDictionary];
  
  return self;
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (![super readFromURL:url error:error]) {
    return NO;
  }

  // Read children
  NSFileManager *fileManager = [[NSFileManager alloc] init];    
  for (NSURL *childURL in [fileManager contentsOfDirectoryAtURL:url includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:0 error:NULL]) {
    if ([_children objectForKey:[childURL lastPathComponent]]) {
      continue;
    }
    NSNumber *isDirectory = nil;
    if (![childURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL]) {
      continue;
    }
    Class childClass = [isDirectory boolValue] ? [ACProjectFolder class] : [ACProjectFile class];
    NSString *childName = childURL.lastPathComponent;
    ACProjectFileSystemItem *child = [[childClass alloc] initWithProject:self.project propertyListDictionary:nil parent:self name:childName];
    if (child) {
      [_children setObject:child forKey:childName];
      [self.project didAddFileSystemItem:child];
    }
    
  }
  return YES;
}

- (BOOL)writeToURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (![super writeToURL:url error:error]) {
    return NO;
  }
  
  // Make sure the directory exists
  NSFileManager *fileManager = [[NSFileManager alloc] init];    
  if (![fileManager fileExistsAtPath:[url path]]) {
    if (![fileManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:error]) {
      return NO;
    }
  }
  
  // Write children
  for (ACProjectFileSystemItem *child in _children.allValues) {
    if (![child writeToURL:[url URLByAppendingPathComponent:child.name] error:error]) {
      return NO;
    }
  }
  
  return YES;
}

- (BOOL)removeSynchronouslyWithError:(NSError *__autoreleasing *)error {
  for (ACProjectFileSystemItem *item in _children.allValues) {
    if (![item removeSynchronouslyWithError:error]) {
      return NO;
    }
  }
  return [super removeSynchronouslyWithError:error];
}

#pragma mark - Accessing folder content

- (NSArray *)children {
  return _children.allValues;
}

- (ACProjectFileSystemItem *)childWithName:(NSString *)name {
  return [_children objectForKey:name];
}

#pragma mark - Creating new folders and files

- (void)addNewFolderWithName:(NSString *)name originalURL:(NSURL *)originalURL completionHandler:(void (^)(ACProjectFolder *, NSError *))completionHandler {
  [self _addNewChildItemWithClass:[ACProjectFolder class] name:name originalURL:originalURL completionHandler:(void(^)(ACProjectFileSystemItem *, NSError *))completionHandler];
}

- (void)addNewFileWithName:(NSString *)name originalURL:(NSURL *)originalURL completionHandler:(void (^)(ACProjectFile *, NSError *))completionHandler {
  [self _addNewChildItemWithClass:[ACProjectFile class] name:name originalURL:originalURL completionHandler:(void(^)(ACProjectFileSystemItem *, NSError *))completionHandler];
}

#pragma mark - Internal Methods

- (void)didRemoveChild:(ACProjectFileSystemItem *)child {
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  ASSERT([_children.allValues containsObject:child]);
  [self willChangeValueForKey:@"children"];
  [_children removeObjectForKey:child.name];
  [self didChangeValueForKey:@"children"];
}

#pragma mark - Private Methods

- (void)_addNewChildItemWithClass:(Class)childClass name:(NSString *)name originalURL:(NSURL *)originalURL completionHandler:(void (^)(ACProjectFileSystemItem *, NSError *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  completionHandler = [completionHandler copy];
  [self.project performAsynchronousFileAccessUsingBlock:^{
    if ([_children objectForKey:name]) {
      if (completionHandler) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
          completionHandler(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:nil]);
        }];
      }
      return;
    }
    ACProjectFileSystemItem *childItem = [[childClass alloc] initWithProject:self.project propertyListDictionary:nil parent:self name:name];
    if (!childItem) {
      if (completionHandler) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
          completionHandler(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil]);
        }];
      }
      return;
    }
    if (originalURL) {
      NSError *error = nil;
      if (![childItem readFromURL:originalURL error:&error]) {
        ASSERT(error);
        if (completionHandler) {
          [NSOperationQueue.mainQueue addOperationWithBlock:^{
            completionHandler(nil, error);
          }];
        }
        return;
      }
    }
    [self _didAddChild:childItem];
    [self.project didAddFileSystemItem:childItem];
    [self.project updateChangeCount:UIDocumentChangeDone];
    if (completionHandler) {
      [NSOperationQueue.mainQueue addOperationWithBlock:^{
        completionHandler(childItem, nil);
      }];
    }
  }];
}

- (ACProjectFileSystemItem *)_addExistingItem:(ACProjectFileSystemItem *)item renameTo:(NSString *)newName error:(NSError *__autoreleasing *)error {
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  // Error if trying to move on the same folder with the same name
  if (item.parentFolder == self && (!newName || [newName isEqualToString:item.name])) {
    if (error) {
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
    }
    return nil;
  }
  // Remove destination item if already existing
  NSFileManager *fileManager = NSFileManager.alloc.init;
  NSURL *newItemURL = [self.fileURL URLByAppendingPathComponent:newName];
  if ([_children objectForKey:newName]) {
    if ([fileManager removeItemAtURL:newItemURL error:nil]) {
      [_children removeObjectForKey:newName];
    }
  }
  // Moving
  if ([fileManager fileExistsAtPath:newItemURL.path] && ![fileManager moveItemAtURL:item.fileURL toURL:newItemURL error:error]) {
    ASSERT(!error || *error);
    return nil;
  }
  
  // Inform of movement
  [item.parentFolder didRemoveChild:item];
  item.fileURL = newItemURL;
  item.parentFolder = self;
  [self _didAddChild:item];
  return item;
}

- (ACProjectFileSystemItem *)_addCopyOfExistingItem:(ACProjectFileSystemItem *)item renameIfNeeded:(BOOL)renameIfNeeded error:(NSError *__autoreleasing *)error {
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  // Get name of destination item
  NSString *name = item.name;
  if (renameIfNeeded) {
    NSInteger currentNumber = 1;
    while ([_children objectForKey:name]) {
      name = [item.name stringByAddingDuplicateNumber:currentNumber];
      ++currentNumber;
    }
  }
  
  // Remove destination item if already existing
  NSURL *childURL = [self.fileURL URLByAppendingPathComponent:name];
  if ([_children objectForKey:name]) {
    if ([NSFileManager.alloc.init removeItemAtURL:childURL error:nil]) {
      [_children removeObjectForKey:name];
    }
  }
  
  // Copy
  ACProjectFileSystemItem *childItem = [[[item class] alloc] initWithProject:self.project propertyListDictionary:nil parent:self name:name];
  if (!childItem) {
    if (error) {
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
    }
    return nil;
  } else {
    if (![childItem readFromURL:item.fileURL error:error]) {
      return nil;
    };
  }
  
  // Inform of copy
  [self _didAddChild:childItem];
  [self.project didAddFileSystemItem:childItem];
  [self.project updateChangeCount:UIDocumentChangeDone];
  return childItem;
}

- (void)_didAddChild:(ACProjectFileSystemItem *)child {
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  ASSERT(![_children.allValues containsObject:child]);
  [self willChangeValueForKey:@"children"];
  [_children setObject:child forKey:child.name];
  [self didChangeValueForKey:@"children"];
}

@end

@implementation ACProjectFileSystemItem (RenamingMovingAndCopying)

- (void)setName:(NSString *)name withCompletionHandler:(void (^)(NSError *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(name && ![name isEqualToString:self.name]);
  completionHandler = [completionHandler copy];
  [self.project performAsynchronousFileAccessUsingBlock:^{
    NSError *error = nil;
    [self.parentFolder _addExistingItem:self renameTo:name error:&error];
    ASSERT(error || [self.name isEqualToString:name]);
    if (completionHandler) {
      [NSOperationQueue.mainQueue addOperationWithBlock:^{
        completionHandler(error);
      }];
    }
  }];
}

- (void)moveToFolder:(ACProjectFolder *)newParent completionHandler:(void (^)(NSError *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(newParent && newParent != self.parentFolder);
  completionHandler = [completionHandler copy];
  [self.project performAsynchronousFileAccessUsingBlock:^{
    NSError *error = nil;
    [newParent _addExistingItem:self renameTo:self.name error:&error];
    ASSERT(error || self.parentFolder == newParent);
    if (completionHandler) {
      [NSOperationQueue.mainQueue addOperationWithBlock:^{
        completionHandler(error);
      }];
    }
  }];
}

- (void)copyToFolder:(ACProjectFolder *)copyParent completionHandler:(void (^)(ACProjectFileSystemItem *, NSError *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(copyParent && copyParent != self.parentFolder);
  completionHandler = [completionHandler copy];
  [self.project performAsynchronousFileAccessUsingBlock:^{
    NSError *error = nil;
    ACProjectFileSystemItem *copy = [copyParent _addCopyOfExistingItem:self renameIfNeeded:NO error:&error];
    ASSERT((copy || error) && !(copy && error));
    if (completionHandler) {
      [NSOperationQueue.mainQueue addOperationWithBlock:^{
        completionHandler(copy, error);
      }];
    }
  }];
}

- (void)duplicateWithCompletionHandler:(void (^)(ACProjectFileSystemItem *, NSError *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  completionHandler = [completionHandler copy];
  [self.project performAsynchronousFileAccessUsingBlock:^{
    NSError *error = nil;
    ACProjectFileSystemItem *copy = [self.parentFolder _addCopyOfExistingItem:self renameIfNeeded:YES error:&error];
    ASSERT((copy || error) && !(copy && error));
    if (completionHandler) {
      [NSOperationQueue.mainQueue addOperationWithBlock:^{
        completionHandler(copy, error);
      }];
    }
  }];
}

@end
