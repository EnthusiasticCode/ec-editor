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

- (ACProjectFileSystemItem *)_addNewCopyOfItem:(ACProjectFileSystemItem *)item renameIfNeeded:(BOOL)renameIfNeeded error:(out NSError **)error;

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

#pragma mark - ACProjectFileSystemItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL originalURL:(NSURL *)originalURL {
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent fileURL:fileURL originalURL:originalURL];
    if (!self) {
        return nil;
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    // Make sure the directory exists
    if (![fileManager fileExistsAtPath:[fileURL path]]) {
        if (![fileManager createDirectoryAtURL:fileURL withIntermediateDirectories:YES attributes:nil error:NULL]) {
            return nil;
        }
    }
    
    // Create children
    _children = [[NSMutableDictionary alloc] init];
    NSDictionary *childrenPlists = [plistDictionary objectForKey:_childrenKey];
    for (NSURL *childURL in [fileManager contentsOfDirectoryAtURL:originalURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:0 error:NULL]) {
        NSNumber *isDirectory = nil;
        if (![childURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL]) {
            continue;
        }
        Class childClass = [isDirectory boolValue] ? [ACProjectFolder class] : [ACProjectFile class];
        NSString *childName = childURL.lastPathComponent;
        ACProjectFileSystemItem *child = [[childClass alloc] initWithProject:project propertyListDictionary:[childrenPlists objectForKey:childName] parent:self fileURL:childURL originalURL:childURL];
        if (child) {
            [_children setObject:child forKey:childName];
            [self.project didAddFileSystemItem:child];
        }
    }

    return self;
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
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    ASSERT([_children.allValues containsObject:child]);
    [_children removeObjectForKey:child.name];
}

#pragma mark - Private Methods

- (void)_addNewChildItemWithClass:(Class)childClass name:(NSString *)name originalURL:(NSURL *)originalURL completionHandler:(void (^)(ACProjectFileSystemItem *, NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [self.project performAsynchronousFileAccessUsingBlock:^{
        if ([_children objectForKey:name]) {
            if (completionHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionHandler(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:nil]);
                }];
            }
            return;
        }
        NSURL *childURL = [self.fileURL URLByAppendingPathComponent:name];
        ACProjectFileSystemItem *childItem = [[childClass alloc] initWithProject:self.project propertyListDictionary:nil parent:self fileURL:childURL originalURL:originalURL ? originalURL : childURL];
        if (!childItem) {
            if (completionHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionHandler(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil]);
                }];
            }
            return;
        }
        [self _didAddChild:childItem];
        [self.project didAddFileSystemItem:childItem];
        [self.project updateChangeCount:UIDocumentChangeDone];
        if (completionHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(childItem, nil);
            }];
        }
    }];
}

- (ACProjectFileSystemItem *)_addExistingItem:(ACProjectFileSystemItem *)item renameTo:(NSString *)newName error:(NSError *__autoreleasing *)error {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    if (item.parentFolder != self && [_children objectForKey:newName]) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
        }
        return nil;
    }
    NSURL *newItemURL = [self.fileURL URLByAppendingPathComponent:newName];
    if (![[[NSFileManager alloc] init] moveItemAtURL:item.fileURL toURL:newItemURL error:error]) {
        ASSERT(!error || *error);
        return nil;
    }
    
    [item.parentFolder didRemoveChild:item];
    item.fileURL = newItemURL;
    item.parentFolder = self;
    [self _didAddChild:item];
    
    return item;
}

- (ACProjectFileSystemItem *)_addNewCopyOfItem:(ACProjectFileSystemItem *)item renameIfNeeded:(BOOL)renameIfNeeded error:(NSError *__autoreleasing *)error {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    NSString *name = item.name;
    if (!renameIfNeeded) {
        if ([_children objectForKey:name]) {
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
            }
            return nil;
        }
    } else {
        NSInteger currentNumber = 1;
        while ([_children objectForKey:name]) {
            name = [item.name stringByAddingDuplicateNumber:currentNumber];
            ++currentNumber;
        }
    }
    NSURL *childURL = [self.fileURL URLByAppendingPathComponent:name];
    ACProjectFileSystemItem *childItem = [[[item class] alloc] initWithProject:self.project propertyListDictionary:nil parent:self fileURL:childURL originalURL:item.fileURL];
    if (!childItem) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
        }
        return nil;
    }    
    [self _didAddChild:childItem];
    [self.project didAddFileSystemItem:childItem];
    [self.project updateChangeCount:UIDocumentChangeDone];
    return childItem;
}

- (void)_didAddChild:(ACProjectFileSystemItem *)child {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    ASSERT(![_children.allValues containsObject:child]);
    [_children setObject:child forKey:child.name];
}

@end

@implementation ACProjectFileSystemItem (RenamingMovingAndCopying)

- (void)setName:(NSString *)name withCompletionHandler:(void (^)(NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ASSERT(name && ![name isEqualToString:self.name]);
    [self.project performAsynchronousFileAccessUsingBlock:^{
        NSError *error = nil;
        [self.parentFolder _addExistingItem:self renameTo:name error:&error];
        ASSERT(error || [self.name isEqualToString:name]);
        if (completionHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(error);
            }];
        }
    }];
}

- (void)moveToFolder:(ACProjectFolder *)newParent completionHandler:(void (^)(NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ASSERT(newParent && newParent != self.parentFolder);
    [self.project performAsynchronousFileAccessUsingBlock:^{
        NSError *error = nil;
        [newParent _addExistingItem:self renameTo:self.name error:&error];
        ASSERT(error || self.parentFolder == newParent);
        if (completionHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(error);
            }];
        }
    }];
}

- (void)copyToFolder:(ACProjectFolder *)copyParent completionHandler:(void (^)(ACProjectFileSystemItem *, NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ASSERT(copyParent && copyParent != self.parentFolder);
    [self.project performAsynchronousFileAccessUsingBlock:^{
        NSError *error = nil;
        ACProjectFileSystemItem *copy = [copyParent _addNewCopyOfItem:self renameIfNeeded:NO error:&error];
        ASSERT((copy || error) && !(copy && error));
        if (completionHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(copy, error);
            }];
        }
    }];
}

- (void)duplicateWithCompletionHandler:(void (^)(ACProjectFileSystemItem *, NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [self.project performAsynchronousFileAccessUsingBlock:^{
        NSError *error = nil;
        ACProjectFileSystemItem *copy = [self.parentFolder _addNewCopyOfItem:self renameIfNeeded:YES error:&error];
        ASSERT((copy || error) && !(copy && error));
        if (completionHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(copy, error);
            }];
        }
    }];
}

@end