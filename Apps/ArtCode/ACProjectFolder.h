//
//  ACProjectFolder.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFolder : ACProjectFileSystemItem

@property (nonatomic, copy, readonly) NSArray *children; // Array of items in the folder (either UUIDs or object references)
- (BOOL)addNewFolderWithName:(NSString *)name error:(NSError **)error;
- (BOOL)addNewFileWithName:(NSString *)name data:(NSData *)data error:(NSError **)error;

@end
