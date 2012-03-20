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

@implementation ACProjectFileSystemItem {
    NSURL *_fileURL;
}

@synthesize name = _name, parentFolder = _parentFolder, contentModificationDate = _contentModificationDate;

#pragma mark - ACProjectItem

- (void)remove {
    ASSERT(self.parentFolder);
    [self.parentFolder didRemoveChild:self];
    [self.project didRemoveFileSystemItem:self];
    [super remove];
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

#pragma mark - Public Methods

- (NSString *)pathInProject {
    if (self.parentFolder == nil) {
        return self.project.name;
    }
    
    return [[self.parentFolder pathInProject] stringByAppendingPathComponent:self.name];
}

#pragma mark - Internal Methods

- (NSURL *)fileURL {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    return _fileURL;
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
    _name = fileURL.lastPathComponent;
    _parentFolder = parent;
    return self;
}

- (BOOL)writeToURL:(NSURL *)url {
    ASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    return NO;
}

@end
