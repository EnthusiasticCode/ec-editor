//
//  ACProjectFile.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFile.h"
#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectItem+Internal.h"

#import "ACProject.h"
#import "ACProjectFolder.h"

#import "ACProjectFileBookmark.h"

#import "TMUnit.h"
#import "TMTheme.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSAttributedString+PersistentDataStructures.h"


static NSString * const _plistFileEncodingKey = @"fileEncoding";
static NSString * const _plistExplicitSyntaxKey = @"explicitSyntax";
static NSString * const _plistBookmarksKey = @"bookmarks";

@interface ACProjectFile ()

@property (nonatomic, copy) NSAttributedString *attributedContent;
@property (atomic, strong) TMUnit *codeUnit;

@end

#pragma mark -

/// Project internal methods to manage bookarks
@interface ACProject (Bookmarks)

- (void)addBookmark:(ACProjectFileBookmark *)bookmark withBlock:(void(^)(void))block;
- (void)removeBookmark:(ACProjectFileBookmark *)bookmark withBlock:(void(^)(void))block;

@end

#pragma mark -

/// Bookmark internal initialization for creation
@interface ACProjectFileBookmark (Internal)

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint;

@end

#pragma mark -

@implementation ACProjectFile {
  NSMutableDictionary *_bookmarks;
  NSUInteger _openCount;
  NSMutableArray *_contentDisposables;
}

@synthesize explicitFileEncoding = _explicitFileEncoding, explicitSyntaxIdentifier = _explicitSyntaxIdentifier, theme = _theme;
@synthesize content = _content, attributedContent = _attributedContent;
@synthesize codeUnit = _codeUnit;

#pragma mark - KVO Overrides

+ (NSSet *)keyPathsForValuesAffectingSyntax {
  return [NSSet setWithObject:@"codeUnit.syntax"];
}

+ (NSSet *)keyPathsForValuesAffectingSymbolList {
  return [NSSet setWithObject:@"codeUnit.symbolList"];
}

+ (NSSet *)keyPathsForValuesAffectingDiagnostics {
  return [NSSet setWithObject:@"codeUnit.diagnostics"];
}

#pragma mark - ACProjectItem

- (ACProjectItemType)type {
  return ACPFile;
}

#pragma mark - ACProjectItem Internal

- (NSDictionary *)propertyListDictionary {
  NSMutableDictionary *plist = super.propertyListDictionary.mutableCopy;
  if (_explicitFileEncoding) {
    [plist setObject:_explicitFileEncoding forKey:_plistFileEncodingKey];
  }
  if (_explicitSyntaxIdentifier) {
    [plist setObject:_explicitSyntaxIdentifier forKey:_plistExplicitSyntaxKey];
  }
  NSMutableDictionary *bookmarks = [[NSMutableDictionary alloc] init];
  [_bookmarks enumerateKeysAndObjectsUsingBlock:^(id point, ACProjectFileBookmark *bookmark, BOOL *stop) {
    if ([point isKindOfClass:[NSNumber class]]) {
      point = [(NSNumber *)point stringValue];
    }
    ASSERT([point isKindOfClass:[NSString class]]);
    [bookmarks setObject:bookmark.propertyListDictionary forKey:point];
  }];
  [plist setObject:bookmarks forKey:_plistBookmarksKey];
  return plist;
}

- (void)setPropertyListDictionary:(NSDictionary *)propertyListDictionary {
  [super setPropertyListDictionary:propertyListDictionary];
  
  _explicitFileEncoding = [propertyListDictionary objectForKey:_plistFileEncodingKey];
  _explicitSyntaxIdentifier = [propertyListDictionary objectForKey:_plistExplicitSyntaxKey];
  [_bookmarks removeAllObjects];
  [[propertyListDictionary objectForKey:_plistBookmarksKey] enumerateKeysAndObjectsUsingBlock:^(id point, NSDictionary *bookmarkPlist, BOOL *stop) {
    NSScanner *scanner = [NSScanner scannerWithString:point];
    NSInteger line;
    if ([scanner scanInteger:&line])
      point = [NSNumber numberWithInteger:line];
    ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self.project propertyListDictionary:bookmarkPlist file:self bookmarkPoint:point];
    if (!bookmark)
      return;
    [self.project addBookmark:bookmark withBlock:^{
      [_bookmarks setObject:bookmark forKey:point];
    }];
  }];
}

- (void)prepareForRemoval {
  for (ACProjectFileBookmark *bookmark in _bookmarks.allValues) {
    [self removeBookmark:bookmark];
  }
}

#pragma mark - ACProjectFileSystemItem Internal

- (NSFileWrapper *)fileWrapper {
  NSFileWrapper *fileWrapper = [NSFileWrapper.alloc initRegularFileWithContents:[self.content dataUsingEncoding:self.fileEncoding]];
  fileWrapper.preferredFilename = self.name;
  return fileWrapper;
}

- (void)setFileWrapper:(NSFileWrapper *)fileWrapper {
  self.content = [NSString.alloc initWithData:fileWrapper.regularFileContents encoding:self.fileEncoding];
}

- (id)initWithProject:(ACProject *)project parent:(ACProjectFolder *)parent fileWrapper:(NSFileWrapper *)fileWrapper propertyListDictionary:(NSDictionary *)plistDictionary {
  self = [super initWithProject:project parent:parent fileWrapper:fileWrapper propertyListDictionary:plistDictionary];
  if (!self) {
    return nil;
  }
  
  _bookmarks = NSMutableDictionary.alloc.init;
  _contentDisposables = NSMutableArray.alloc.init;
  
  self.fileWrapper = fileWrapper;
  self.propertyListDictionary = plistDictionary;
    
  return self;
}

#pragma mark - File metadata

- (NSStringEncoding)fileEncoding {
  NSNumber *explicitEncoding = self.explicitFileEncoding;
  if (!explicitEncoding) {
    return NSUTF8StringEncoding;
  } else {
    return [explicitEncoding unsignedIntegerValue];
  }
}

#pragma mark - Managing semantic content

- (TMSyntaxNode *)syntax {
  return _codeUnit.syntax;
}

- (void)setSyntax:(TMSyntaxNode *)syntax {
  _codeUnit.syntax = syntax;
}

- (void)setTheme:(TMTheme *)theme {
  if (theme == _theme) {
    return;
  }
  _theme = theme;
  self.attributedContent = [self.attributedContent attributedStringBySettingAttributes:theme.commonAttributes range:NSMakeRange(0, self.attributedContent.length)];
}

- (NSArray *)symbolList {
  return _codeUnit.symbolList;
}

- (NSArray *)diagnostics {
  return _codeUnit.diagnostics;
}

#pragma mark - Managing file bookmarks

- (NSArray *)bookmarks {
  return [_bookmarks allValues];
}

- (void)addBookmarkWithPoint:(id)point {
  ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self.project propertyListDictionary:nil file:self bookmarkPoint:point];
  [self willChangeValueForKey:@"bookmarks"];
  [self.project addBookmark:bookmark withBlock:^{
    [_bookmarks setObject:bookmark forKey:point];
    [self.project updateChangeCount:UIDocumentChangeDone];
  }];
  [self didChangeValueForKey:@"bookmarks"];
}

- (void)removeBookmark:(ACProjectFileBookmark *)bookmark {
  [self willChangeValueForKey:@"bookmarks"];
  [self.project removeBookmark:bookmark withBlock:^{
    [bookmark prepareForRemoval];
    [_bookmarks removeObjectForKey:bookmark.bookmarkPoint];
    [self.project updateChangeCount:UIDocumentChangeDone];
  }];
  [self didChangeValueForKey:@"bookmarks"];
}

- (ACProjectFileBookmark *)bookmarkForPoint:(id)point {
  return [_bookmarks objectForKey:point];
}

@end

#pragma mark -

@implementation ACProjectFile (RACExtensions)

- (RACSubscribable *)rac_qualifiedScopeIdentifierAtOffset:(NSUInteger)offset {
  return [[RACSubscribable startWithScheduler:self.project.codeIndexingScheduler block:^id(BOOL *success, NSError *__autoreleasing *error) {
    return [self.codeUnit qualifiedScopeIdentifierAtOffset:offset];
  }] deliverOn:[RACScheduler mainQueueScheduler]];
}

- (RACSubscribable *)rac_completionsAtOffset:(NSUInteger)offset {
  return [[RACSubscribable startWithScheduler:self.project.codeIndexingScheduler block:^id(BOOL *success, NSError *__autoreleasing *error) {
    return [self.codeUnit qualifiedScopeIdentifierAtOffset:offset];
  }] deliverOn:[RACScheduler mainQueueScheduler]];
}

@end
