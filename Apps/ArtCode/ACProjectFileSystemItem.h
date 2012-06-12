//
//  ACProjectFileSystemItem.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectItem.h"

@class ACProjectFolder;

@interface ACProjectFileSystemItem : ACProjectItem

#pragma mark Item Properties

/// A reference to the folder that contain this item. nil if the item is a root one.
@property (nonatomic, weak, readonly) ACProjectFolder *parentFolder;

/// Name of the file system item
@property (nonatomic, copy) NSString *name;

/// URL of the file system item. (Do not use to access contents of the item)
@property (nonatomic, strong, readonly) NSURL *fileURL;

/// String containing the path relative to the project and starting with the project name.
@property (nonatomic, readonly) NSString *pathInProject;

#pragma mark Item Contents

/// Replaces the contents of the receiver with those at the given URL.
- (void)updateWithContentsOfURL:(NSURL *)url completionHandler:(void(^)(BOOL success))completionHandler;

/// Publishes the contents of the receiver to the specified URL. Replaces items at destination.
- (void)publishContentsToURL:(NSURL *)url completionHandler:(void(^)(BOOL success))completionHandler;

@end

@interface ACProjectFileSystemItem (RenamingMovingAndCopying)

#pragma mark Renaming, Moving and Copying

/// Move the item to a given folder. Optionally rename the item.
- (void)moveToFolder:(ACProjectFolder *)newParent renameTo:(NSString *)newName;

/// Copy the item to a given folder. Optionally rename the item. Returns the copy.
- (ACProjectFileSystemItem *)copyToFolder:(ACProjectFolder *)copyParent renameTo:(NSString *)newName;

@end