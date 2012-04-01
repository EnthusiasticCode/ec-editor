//
//  ACProjectFile.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"
@class ACProjectFileBookmark, CodeBuffer;

@interface ACProjectFile : ACProjectFileSystemItem

#pragma mark File metadata
/// @name File metadata

/// The size of the file in bytes
@property (nonatomic, readonly) NSUInteger fileSize;

/// A value of type NSStringEncoding wrapped in an NSNumber indicating what encoding should be used to read the file. If nil it will be autodetected
@property (nonatomic, strong) NSNumber *explicitFileEncoding;

/// file syntax to be used for syntax highlight. If nil it will be autodetected
@property (nonatomic, strong) NSString *explicitSyntaxIdentifier;

#pragma mark Accessing the content
/// @name Accessing the content

/// Attempts to read the contents of the file.
/// 
/// Must be balanced by a call to closeWithCompletionHandler:
- (void)openWithCompletionHandler:(void(^)(NSError *error))completionHandler;

/// Closes the file.
- (void)closeWithCompletionHandler:(void(^)(NSError *error))completionHandler;

/// This returns a code file with the project file's contents.
@property (nonatomic, strong, readonly) CodeBuffer *codeBuffer;

#pragma mark Managing file bookmarks
/// @name Managing file bookmarks

/// Get the bookmarks for the file.
- (NSArray *)bookmarks;

/// Add a bookmark to the file.
- (void)addBookmarkWithPoint:(id)point;

/// Get a bookmark in this file with the given point if present.
- (ACProjectFileBookmark *)bookmarkForPoint:(id)point;

@end
