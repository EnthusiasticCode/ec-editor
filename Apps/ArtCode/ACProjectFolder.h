//
//  ACProjectFolder.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@class ACProjectFile;


@interface ACProjectFolder : ACProjectFileSystemItem

#pragma mark Accessing folder content

/// Array of items in the folder.
@property (nonatomic, copy, readonly) NSArray *children;

/// Gets the child with the given name if it exists, nil otherwise.
- (ACProjectFileSystemItem *)childWithName:(NSString *)name;

#pragma mark Creating and deleting folders and files

- (ACProjectFolder *)newChildFolderWithName:(NSString *)name;

- (ACProjectFile *)newChildFileWithName:(NSString *)name;

- (void)removeChildItem:(ACProjectFileSystemItem *)childItem;

@end
