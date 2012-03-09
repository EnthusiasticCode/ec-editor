//
//  ACProject_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
@class ACProjectFileBookmark, ACProjectFileSystemItem, ACProjectRemote;

@interface ACProject (Internal)

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;
- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;

+ (void)updateCacheForProject:(ACProject *)project;

@end
