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

#pragma mark - 

@implementation ACProjectFolder {
    /// Dictionary of item name to ACProjectFileSystemItem.
    NSMutableDictionary *_children;
}

#pragma mark - ACProjectItem

- (NSURL *)URL {
    if (self.parentFolder == nil) {
        return [self.project.fileURL URLByAppendingPathComponent:self.name isDirectory:YES];
    }
    return [self.parentFolder.URL URLByAppendingPathComponent:self.name isDirectory:YES];
}

- (ACProjectItemType)type {
    return ACPFolder;
}

- (void)remove {
    for (ACProjectFileSystemItem *item in _children.allValues) {
        [item remove];
    }
    [super remove];
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

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL {
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent fileURL:fileURL];
    if (!self) {
        return nil;
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    // Make sure the directory exists
    [fileManager createDirectoryAtURL:fileURL withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Create children
    _children = [[NSMutableDictionary alloc] init];
    NSDictionary *childrenPlists = [plistDictionary objectForKey:_childrenKey];
    for (NSURL *childURL in [fileManager contentsOfDirectoryAtURL:fileURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:0 error:NULL]) {
        NSNumber *isDirectory = nil;
        if (![childURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL]) {
            continue;
        }
        Class childClass = [isDirectory boolValue] ? [ACProjectFolder class] : [ACProjectFile class];
        NSString *childName = childURL.lastPathComponent;
        ACProjectFileSystemItem *child = [[childClass alloc] initWithProject:project propertyListDictionary:[childrenPlists objectForKey:childName] parent:self fileURL:childURL];
        if (child) {
            [_children setObject:child forKey:childName];
        }
    }

    return self;
}

#pragma mark - Accessing folder content

- (NSArray *)children {
    return _children.allValues;
}

- (ACProjectFileSystemItem *)childWithName:(NSString *)name {
    return [_children objectForKey:name];
}

#pragma mark - Creating new folders and files

- (void)addNewFolderWithName:(NSString *)name plist:(NSDictionary *)plist originalURL:(NSURL *)originalURL completionHandler:(void (^)(ACProjectFolder *))completionHandler {
    if ([_children objectForKey:name]) {
        completionHandler(nil);
        return;
    }
    NSURL *childURL = [self.URL URLByAppendingPathComponent:name];
    [self.project performAsynchronousFileAccessUsingBlock:^{
        ACProjectFolder *childFolder = [[ACProjectFolder alloc] initWithProject:self.project propertyListDictionary:plist parent:self fileURL:childURL];
        if (!childFolder) {
            completionHandler(nil);
            return;
        }
        [_children setObject:childFolder forKey:name];
        [self.project didAddFileSystemItem:childFolder];
        [self.project updateChangeCount:UIDocumentChangeDone];
        completionHandler(childFolder);
    }];
}

- (void)addNewFileWithName:(NSString *)name plist:(NSDictionary *)plist originalURL:(NSURL *)originalURL completionHandler:(void (^)(ACProjectFile *))completionHandler {
    if ([_children objectForKey:name]) {
        completionHandler(nil);
        return;
    }
    NSURL *childURL = [self.URL URLByAppendingPathComponent:name];
    [self.project performAsynchronousFileAccessUsingBlock:^{
        ACProjectFile *childFile = [[ACProjectFile alloc] initWithProject:self.project propertyListDictionary:plist parent:self fileURL:childURL];
        if (!childFile) {
            completionHandler(nil);
            return;
        }
        [_children setObject:childFile forKey:name];
        [self.project didAddFileSystemItem:childFile];
        [self.project updateChangeCount:UIDocumentChangeDone];
        completionHandler(childFile);
    }];
}

#pragma mark - Internal Methods

- (void)didRemoveChild:(ACProjectFileSystemItem *)child {
    ECASSERT([_children.allValues containsObject:child]);
    [_children removeObjectForKey:child.name];
}

@end
