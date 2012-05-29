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

/// Attributed content of the file
@property (nonatomic, copy, readonly) NSAttributedString *attributedContent;

#pragma mark Managing semantic content

/// The syntax used to interpret the file's contents.
/// Will be autodetected if not set.
@property (nonatomic, strong) TMSyntaxNode *syntax;

/// The theme used to color the source code.
/// The default theme will be used if not set.
@property (nonatomic, strong) TMTheme *theme;

/// An array of TMSymbol objects representing all the symbols in the file.
@property (nonatomic, strong, readonly) NSArray *symbolList;

/// Warnings, errors and other diagnostics in the file.
@property (nonatomic, strong, readonly) NSArray *diagnostics;

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

@class RACSubscribable;

@interface ACProjectFile (RACExtensions)

- (RACSubscribable *)rac_qualifiedScopeIdentifierAtOffset:(NSUInteger)offset;
- (RACSubscribable *)rac_completionsAtOffset:(NSUInteger)offset;

@end
