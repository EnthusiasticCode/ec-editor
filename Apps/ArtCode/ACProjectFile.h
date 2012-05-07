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

/// Presenters are retained by the receiver, so each add must be balanced by a remove to avoid retain cycles
- (void)addPresenter:(id<ACProjectFilePresenter>)presenter;
- (void)removePresenter:(id<ACProjectFilePresenter>)presenter;
- (NSArray *)presenters;

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

- (NSUInteger)length;
- (NSString *)string;
- (NSString *)substringWithRange:(NSRange)range;
- (NSRange)lineRangeForRange:(NSRange)range;
- (NSAttributedString *)attributedString;
- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range;
- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;
- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range;
- (NSDictionary *)attributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)range;
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;
- (void)removeAttribute:(NSString *)name range:(NSRange)range;

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

/// Returns the qualified identifier of the deepest scope at the specified offset
- (void)qualifiedScopeIdentifierAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(NSString *qualifiedScopeIdentifier))completionHandler;

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (void)completionsAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(id<TMCompletionResultSet>completions))completionHandler;

#pragma mark Managing file bookmarks
/// @name Managing file bookmarks

/// Get the bookmarks for the file.
- (NSArray *)bookmarks;

/// Add a bookmark to the file.
- (void)addBookmarkWithPoint:(id)point;

/// Get a bookmark in this file with the given point if present.
- (ACProjectFileBookmark *)bookmarkForPoint:(id)point;

@end

@protocol ACProjectFilePresenter <NSObject>

@optional
- (void)projectFile:(ACProjectFile *)projectFile willReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;
- (void)projectFile:(ACProjectFile *)projectFile didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string;
- (void)projectFile:(ACProjectFile *)projectFile willChangeAttributesInRange:(NSRange)range;
- (void)projectFile:(ACProjectFile *)projectFile didChangeAttributesInRange:(NSRange)range;

@end
