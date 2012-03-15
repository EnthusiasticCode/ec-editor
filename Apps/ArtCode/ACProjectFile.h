//
//  ACProjectFile.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"
@class ACProjectFileBookmark, CodeFile;

@interface ACProjectFile : ACProjectFileSystemItem

/// The size of the file in bytes
@property (nonatomic, readonly) NSUInteger fileSize;

/// Default NSUTF8FileEncoding
@property (nonatomic) NSStringEncoding fileEncoding;

#pragma mark Code File specific properties

/// file syntax to be used for syntax highlight. If nill the system should use the most appropriate file type based on the file path
@property (nonatomic, strong) NSString *codeFileExplicitSyntaxIdentifier;

/// Returns the explicit file syntax identifier or one derived from the file path or content
- (NSString *)codeFileSyntaxIdentifier;

/// This returns an opened code file with the project file's contents. The returned code file MUST be released before releasing the associated project file 
- (void)openCodeFileWithCompletionHandler:(void(^)(CodeFile *codeFile))completionHandler;

#pragma mark Managing file bookmarks

/// Get the bookmarks for the file.
- (NSArray *)bookmarks;

/// Add a bookmark to the file.
- (void)addBookmarkWithPoint:(id)point;

/// Get a bookmark in this file with the given point if present.
- (ACProjectFileBookmark *)bookmarkForPoint:(id)point;

@end
