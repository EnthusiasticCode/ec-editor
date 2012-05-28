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

/// The name of the item corresponding to its filesystem path component.
@property (nonatomic, strong, readonly) NSString *name;

/// The last modified date
@property (nonatomic, strong, readonly) NSDate *contentModificationDate;

/// Returns a string containing the path relative to the project and starting with the project name.
- (NSString *)pathInProject;

#pragma mark Item Contents

/// Recursively updates the contents of the receiver by adding or replacing items. Does not delete items 
- (void)updateWithContentsOfURL:(NSURL *)url completionHandler:(void(^)(BOOL success))completionHandler;

/// Recusivly publishes the contents of the receiver to the specified URL. Replaces items at destination.
- (void)publishContentsToURL:(NSURL *)url completionHandler:(void(^)(BOOL success))completionHandler;

/// Delete contents from disk. Called by -remove
- (void)removeWithCompletionHandler:(void(^)(BOOL success))completionHandler;

@end

@interface ACProjectFileSystemItem (RenamingMovingAndCopying)

#pragma mark Renaming, Moving and Copying

/// Rename an item
- (void)setName:(NSString *)name withCompletionHandler:(void(^)(BOOL success))completionHandler;

/// Move the item to a new folder.
- (void)moveToFolder:(ACProjectFolder *)newParent completionHandler:(void(^)(BOOL success))completionHandler;

/// Copy the item to a new folder.
- (void)copyToFolder:(ACProjectFolder *)copyParent completionHandler:(void(^)(ACProjectFileSystemItem *copy))completionHandler;

// Duplicate the receiver and changes its name accordingly.
- (void)duplicateWithCompletionHandler:(void(^)(ACProjectFileSystemItem *duplicate))completionHandler;

@end