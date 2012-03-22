//
//  ACProjectFile.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"
@class ACProjectFileBookmark, CodeFile, TMSyntaxNode, TMUnit;

@interface ACProjectFile : ACProjectFileSystemItem

#pragma mark File metadata
/// @name File metadata

/// The size of the file in bytes
@property (nonatomic, readonly) NSUInteger fileSize;

/// A value of type NSStringEncoding wrapped in an NSNumber indicating what encoding should be used to read the file. If nil it will be autodetected
@property (nonatomic, strong) NSNumber *explicitFileEncoding;

/// The file encoding being used to read the file contents. Defaults to UTF8
@property (nonatomic, readonly) NSStringEncoding fileEncoding;

/// file syntax to be used for syntax highlight. If nil it will be autodetected
@property (nonatomic, strong) NSString *explicitSyntaxIdentifier;

/// Returns the explicit file syntax identifier or one derived from the file path or content
@property (nonatomic, strong, readonly) NSString *syntaxIdentifier;

#pragma mark Accessing the content
/// @name Accessing the content

/// Attempts to read the contents of the file.
/// 
/// Must be balanced by a call to closeWithCompletionHandler:
- (void)openWithCompletionHandler:(void(^)(NSError *error))completionHandler;

/// Closes the file.
- (void)closeWithCompletionHandler:(void(^)(NSError *error))completionHandler;

/// This returns a code file with the project file's contents.
@property (nonatomic, strong, readonly) CodeFile *codeFile;

/// The syntax being used to create the code unit
@property (nonatomic, strong, readonly) TMSyntaxNode *syntax;

/// The code unit for the file.
@property (nonatomic, strong, readonly) TMUnit *codeUnit;

#pragma mark Managing file bookmarks
/// @name Managing file bookmarks

/// Get the bookmarks for the file.
- (NSArray *)bookmarks;

/// Add a bookmark to the file.
- (void)addBookmarkWithPoint:(id)point;

/// Get a bookmark in this file with the given point if present.
- (ACProjectFileBookmark *)bookmarkForPoint:(id)point;

@end
