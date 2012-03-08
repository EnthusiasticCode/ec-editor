//
//  ACProjectFolder.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFolder : ACProjectFileSystemItem

#pragma mark Accessing folder's content

/// Array of items in the folder.
@property (nonatomic, copy, readonly) NSArray *children;

/// Retrieves an item descendant of the receiver's that has the given UUID.
- (ACProjectFileSystemItem *)descendantItemWithUUID:(NSString *)uuid;

#pragma mark Creating new folders and files

- (BOOL)addNewFolderWithName:(NSString *)name contents:(NSFileWrapper *)contents plist:(NSDictionary *)plist error:(NSError **)error;
- (BOOL)addNewFileWithName:(NSString *)name contents:(NSFileWrapper *)contents plist:(NSDictionary *)plist error:(NSError **)error;

@end
