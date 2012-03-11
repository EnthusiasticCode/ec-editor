//
//  ACProjectFile.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"

@interface ACProjectFile : ACProjectFileSystemItem

/// Default NSUTF8FileEncoding
@property (nonatomic) NSStringEncoding fileEncoding;

#pragma mark Code File specific properties

/// file syntax to be used for syntax highlight. If nill the system should use the most appropriate file type based on the file path
@property (nonatomic, strong) NSString *codeFileExplicitSyntaxIdentifier;

/// Returns the explicit file syntax identifier or one derived from the file path or content
- (NSString *)codeFileSyntaxIdentifier;

#pragma mark Managing file bookmarks

/// Add a bookmark to the file.
- (void)addBookmarkWithPoint:(id)point;

/// Get the bookmarks for the file.
- (NSArray *)bookmarks;

@end
