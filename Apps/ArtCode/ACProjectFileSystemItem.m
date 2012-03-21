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
    return [self initWithProject:project propertyListDictionary:plistDictionary parent:nil fileURL:nil originalURL:nil];
}

- (NSDictionary *)propertyListDictionary {
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:self.name forKey:@"name"];
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

- (void)removeWithCompletionHandler:(void (^)(NSError *))completionHandler {
    [self.project performAsynchronousFileAccessUsingBlock:^{
        NSError *error = nil;
        if (![self removeSynchronouslyWithError:&error]) {
            ASSERT(error);
            if (completionHandler) {
                completionHandler(error);
            }
        } else {
            [super remove];
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    }];
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

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL originalURL:(NSURL *)originalURL {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]); // All filesystem items need to be initialized in the project's file access coordination queue
    if (!project || !fileURL || !originalURL || ![fileURL isFileURL] || ![originalURL isFileURL]) {
        return nil;
    }
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self) {
        return nil;
    }
    NSDate *contentModificationDate = nil;
    [originalURL getResourceValue:&contentModificationDate forKey:NSURLContentModificationDateKey error:NULL];
    if (!contentModificationDate) {
        contentModificationDate = [[NSDate alloc] init];
    }
    
    if (![fileURL isEqual:originalURL]) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if (![fileManager copyItemAtURL:originalURL toURL:fileURL error:NULL]) {
            [fileManager removeItemAtURL:fileURL error:NULL];
            return nil;
        }
    }
    
    _contentModificationDate = contentModificationDate;
    _fileURL = fileURL;
    _parentFolder = parent;
    return self;
}

- (BOOL)writeToURL:(NSURL *)url {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    if ([url isEqual:self.fileURL]) {
        return YES;
    } else {
        return [[[NSFileManager alloc] init] copyItemAtURL:self.fileURL toURL:url error:NULL];
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
