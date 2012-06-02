//
//  ACProjectFile.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"
@class ACProjectFileBookmark, CodeBuffer, TMSyntaxNode, TMTheme;
@protocol TMCompletionResultSet, ACProjectFilePresenter;

@interface ACProjectFile : ACProjectFileSystemItem

#pragma mark File metadata
/// @name File metadata

/// A value of type NSStringEncoding wrapped in an NSNumber indicating what encoding should be used to read and write the file. If nil it will be autodetected
@property (nonatomic, strong) NSNumber *explicitFileEncoding;

/// The encoding used to read and write the file. Derived from explicitFileEncoding or autodetected.
@property (nonatomic, readonly) NSStringEncoding fileEncoding;

/// file syntax to be used for syntax highlight. If nil it will be autodetected
@property (nonatomic, strong) NSString *explicitSyntaxIdentifier;

#pragma mark File content

/// Unattributed content of the file
@property (nonatomic, copy) NSString *content;

#pragma mark Managing file bookmarks
/// @name Managing file bookmarks

/// Get the bookmarks for the file.
- (NSArray *)bookmarks;

/// Add a bookmark to the file.
- (void)addBookmarkWithPoint:(id)point;

/// Get a bookmark in this file with the given point if present.
- (ACProjectFileBookmark *)bookmarkForPoint:(id)point;

/// Remove a bookmark
- (void)removeBookmark:(ACProjectFileBookmark *)bookmark;

@end
