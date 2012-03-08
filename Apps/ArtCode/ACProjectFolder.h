//
//  ACProjectFolder.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFolder : ACProjectFileSystemItem

/// Array of items in the folder.
@property (nonatomic, copy, readonly) NSArray *children;

/// Retrieves an item descendant of the receiver's that has the given UUID.
- (ACProjectFileSystemItem *)descendantItemWithUUID:(NSString *)uuid;

#pragma mark Creating new folders and files

- (BOOL)addNewFolderWithName:(NSString *)name error:(NSError **)error;
- (BOOL)addNewFileWithName:(NSString *)name data:(NSData *)data error:(NSError **)error;

@end
