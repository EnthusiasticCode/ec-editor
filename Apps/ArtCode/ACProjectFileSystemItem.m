//
//  ACProjectFileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectItem+Internal.h"
#import "ACProject.h"

#import "ACProjectFolder.h"

#import "NSURL+Utilities.h"


@interface ACProject (FileSystemItems)

- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;

@end

#pragma mark -

/// Folder internal method to remove a child item
@interface ACProjectFolder (Internal)

- (void)didRemoveChild:(ACProjectFileSystemItem *)child;

@end

#pragma mark -

@implementation ACProjectFileSystemItem

@synthesize parentFolder = _parentFolder, contentModificationDate = _contentModificationDate, fileURL = _fileURL;

#pragma mark - ACProjectItem

- (void)remove {
    [self removeWithCompletionHandler:nil];
}

#pragma mark - ACProjectItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary {
    return [self initWithProject:project propertyListDictionary:plistDictionary parent:nil fileURL:nil];
}

- (NSDictionary *)propertyListDictionary {
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    return plist;
}

#pragma mark - Item Properties

- (NSString *)name {
    return [_fileURL lastPathComponent];
}

- (NSString *)pathInProject {
    if (self.parentFolder == nil) {
        return self.project.name;
    }
    
    return [[self.parentFolder pathInProject] stringByAppendingPathComponent:self.name];
}

#pragma mark - Item Contents

#define PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER(method_call) \
ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);\
[self.project performAsynchronousFileAccessUsingBlock:^{\
NSError *error = nil;\
if (!method_call) {\
if (completionHandler) {\
[[NSOperationQueue mainQueue] addOperationWithBlock:^{\
completionHandler(error);\
}];\
}\
} else {\
if (completionHandler) {\
[[NSOperationQueue mainQueue] addOperationWithBlock:^{\
completionHandler(nil);\
}];\
}\
}\
}]


- (void)updateWithContentsOfURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler {
    PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER([self readFromURL:url error:&error]);
}

- (void)publishContentsToURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler {
    PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER([self writeToURL:url error:&error]);
}

- (void)removeWithCompletionHandler:(void (^)(NSError *))completionHandler {
    PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER([self removeSynchronouslyWithError:&error]);
}

#pragma mark - Internal Methods

- (NSURL *)fileURL {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    return _fileURL;
}

- (void)setFileURL:(NSURL *)fileURL {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    _fileURL = fileURL;
}

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL {
    // All filesystem items need to be initialized in the project's file access coordination queue
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    // If parameters aren't good, return nil
    if (!project || !fileURL || ![fileURL isFileURL]) {
        return nil;
    }
    
    // Initialize the item
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self) {
        return nil;
    }
    _parentFolder = parent;
    _fileURL = fileURL;
    
    // Try to get the content modification date
    NSDate *contentModificationDate = nil;
    [fileURL getResourceValue:&contentModificationDate forKey:NSURLContentModificationDateKey error:NULL];
    if (!contentModificationDate) {
        contentModificationDate = [[NSDate alloc] init];
    }
    _contentModificationDate = contentModificationDate;
    
    return self;
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    if ([url isEqual:self.fileURL]) {
        return YES;
    } else {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if ([fileManager fileExistsAtPath:self.fileURL.path]) {
            NSURL *temporaryDirectory = [NSURL temporaryDirectory];
            if (![fileManager createDirectoryAtURL:temporaryDirectory withIntermediateDirectories:YES attributes:nil error:error]) {
                ASSERT(error);
                return NO;
            }
            NSURL *temporaryItem = [temporaryDirectory URLByAppendingPathComponent:[url lastPathComponent]];
            if (![fileManager copyItemAtURL:url toURL:temporaryItem error:error]) {
                ASSERT(error);
                return NO;
            }
            if (![fileManager replaceItemAtURL:self.fileURL withItemAtURL:temporaryItem backupItemName:nil options:0 resultingItemURL:NULL error:error]) {
                ASSERT(error);
                return NO;
            }
            [fileManager removeItemAtURL:temporaryDirectory error:NULL];
        } else {
            [fileManager createDirectoryAtURL:[self.fileURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
            if (![fileManager copyItemAtURL:url toURL:self.fileURL error:error]) {
                ASSERT(error);
                return NO;
            }
        }
        NSDate *contentModificationDate = nil;
        if([url getResourceValue:&contentModificationDate forKey:NSURLContentModificationDateKey error:NULL]) {
            _contentModificationDate = contentModificationDate;
        } else {
            _contentModificationDate = [[NSDate alloc] init];
        }
    }
    return YES;
}

- (BOOL)writeToURL:(NSURL *)url error:(out NSError *__autoreleasing *)error {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    if ([url isEqual:self.fileURL]) {
        return YES;
    } else {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager createDirectoryAtURL:[url URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
        return [fileManager copyItemAtURL:self.fileURL toURL:url error:error];
    }
}

- (BOOL)removeSynchronouslyWithError:(NSError *__autoreleasing *)error
{
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    if (![[[NSFileManager alloc] init] removeItemAtURL:self.fileURL error:error]) {
        ASSERT(!error || *error);
        return NO;
    } else {
        [self.parentFolder didRemoveChild:self];
        [self.project didRemoveFileSystemItem:self];
        return YES;
    }
}

@end
