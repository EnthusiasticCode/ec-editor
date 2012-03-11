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
@property (nonatomic, strong) NSString *name;

/// Returns a string containing the path relative to the project and starting with /.
- (NSString *)pathRelativeToProject;

#pragma mark Managing the item

/// Move the item to a new folder.
- (BOOL)moveToFolder:(ACProjectFolder *)newParent error:(NSError **)error;

/// Copy the item to a new folder.
- (BOOL)copyToFolder:(ACProjectFolder *)copyParent error:(NSError **)error;

@end
