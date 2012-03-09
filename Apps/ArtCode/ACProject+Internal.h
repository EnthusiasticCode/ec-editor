//
//  ACProject_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
@class ACProjectFileBookmark, ACProjectFileSystemItem;

@interface ACProject (Internal)

- (void)didAddBookmark:(ACProjectFileBookmark *)bookmark;
- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark;

- (void)didAddFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;
- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;

@end
