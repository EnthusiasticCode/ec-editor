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


static NSString * const _plistFileEncodingKey = @"fileEncoding";
static NSString * const _plistExplicitSyntaxKey = @"explicitSyntax";
static NSString * const _plistBookmarksKey = @"bookmarks";

@interface ACProjectFile ()

@property (nonatomic, strong) TMUnit *codeUnit;

@end

#pragma mark -

/// Project internal methods to manage bookarks
@interface ACProject (Bookmarks)

- (void)didAddBookmark:(ACProjectFileBookmark *)bookmark;
- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark;

@end

#pragma mark -

/// Bookmark internal initialization for creation
@interface ACProjectFileBookmark (Internal)

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint;

@end

#pragma mark -

@implementation ACProjectFile {
  NSMutableSet *_presenters;
  NSMutableDictionary *_bookmarks;
  NSUInteger _openCount;
  NSMutableAttributedString *_contents;
}

@synthesize fileSize = _fileSize, explicitFileEncoding = _explicitFileEncoding, explicitSyntaxIdentifier = _explicitSyntaxIdentifier, theme = _theme;
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

- (void)remove {
  for (ACProjectFileBookmark *bookmark in _bookmarks.allValues) {
    [bookmark remove];
  }
  [super remove];
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

#pragma mark - ACProjectFileSystemItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL {
  self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent fileURL:fileURL];
  if (!self) {
    return nil;
  }
  
  // Make sure the file exists
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  if (![fileManager fileExistsAtPath:fileURL.path]) {
    if (![@"" writeToURL:fileURL atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
      return nil;
    }
  }
  
  _presenters = NSMutableSet.alloc.init;
  
  NSNumber *fileSize = nil;
  [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
  _fileSize = [fileSize unsignedIntegerValue];
  _explicitFileEncoding = [plistDictionary objectForKey:_plistFileEncodingKey];
  _explicitSyntaxIdentifier = [plistDictionary objectForKey:_plistExplicitSyntaxKey];
  _bookmarks = [[NSMutableDictionary alloc] init];
  [[plistDictionary objectForKey:_plistBookmarksKey] enumerateKeysAndObjectsUsingBlock:^(id point, NSDictionary *bookmarkPlist, BOOL *stop) {
    NSScanner *scanner = [NSScanner scannerWithString:point];
    NSInteger line;
    if ([scanner scanInteger:&line])
      point = [NSNumber numberWithInteger:line];
    ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:project propertyListDictionary:bookmarkPlist file:self bookmarkPoint:point];
    if (!bookmark)
      return;
    [_bookmarks setObject:bookmark forKey:point];
    [project didAddBookmark:bookmark];
  }];
  return self;
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (![super readFromURL:url error:error]) {
    return NO;
  }
  // Make sure the file exists
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  if (![fileManager fileExistsAtPath:self.fileURL.path]) {
    if (![@"" writeToURL:self.fileURL atomically:NO encoding:NSUTF8StringEncoding error:error]) {
      return NO;
    }
  }
  
  NSNumber *fileSize = nil;
  if (![self.fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:error]) {
    return NO;
  };
  _fileSize = [fileSize unsignedIntegerValue];
  return YES;
}

- (BOOL)writeToURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  NSString *contents = _contents.string;
  NSStringEncoding encoding;
  if (_explicitFileEncoding) {
    encoding = [_explicitFileEncoding unsignedIntegerValue];
  } else {
    encoding = NSUTF8StringEncoding;
  }
  [contents writeToURL:url atomically:YES encoding:encoding error:error];
  return [super writeToURL:url error:error];
}

#pragma mark - Public Methods

- (void)addPresenter:(id<ACProjectFilePresenter>)presenter {
  [_presenters addObject:presenter];
}

- (void)removePresenter:(id<ACProjectFilePresenter>)presenter {
  [_presenters removeObject:presenter];
}

- (NSArray *)presenters {
  return _presenters.allObjects;
}

#pragma mark - Accessing the content

- (void)openWithCompletionHandler:(void (^)(NSError *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if (_openCount) {
    completionHandler(nil);
    return;
  }
  NSStringEncoding encoding;
  if (_explicitFileEncoding) {
    encoding = [_explicitFileEncoding unsignedIntegerValue];
  } else {
    encoding = NSUTF8StringEncoding;
  }
  __block TMTheme *theme = self.theme;
  __weak ACProjectFile *weakSelf = self;
  [self.project performAsynchronousFileAccessUsingBlock:^{
    NSError *error = nil;
    NSMutableAttributedString *contents = nil;
    NSURL *fileURL = nil;
    ACProjectFile *outerStrongSelf = weakSelf;
    if (outerStrongSelf) {
      if (!theme) {
        theme = [TMTheme defaultTheme];
      }
      contents = [NSMutableAttributedString.alloc initWithString:[NSString.alloc initWithContentsOfURL:outerStrongSelf.fileURL encoding:encoding error:&error] attributes:theme.commonAttributes];
      fileURL = outerStrongSelf.fileURL;
    }
    if (contents) {
      [NSOperationQueue.mainQueue addOperationWithBlock:^{
        ACProjectFile *innerStrongSelf = weakSelf;
        if (innerStrongSelf) {
          innerStrongSelf->_contents = contents;
          innerStrongSelf->_theme = theme;
          ++innerStrongSelf->_openCount;
          innerStrongSelf.codeUnit = [TMUnit.alloc initWithFileURL:fileURL index:nil];
          [innerStrongSelf.codeUnit reparseWithUnsavedContent:contents.string];
          [innerStrongSelf.codeUnit enumerateQualifiedScopeIdentifiersAsynchronouslyInRange:NSMakeRange(0, contents.length) withBlock:^(NSString *qualifiedScopeIdentifier, NSRange range, BOOL *stop) {
            NSDictionary *attributes = [self.theme attributesForQualifiedIdentifier:qualifiedScopeIdentifier];
            if (attributes) {
              [self addAttributes:attributes range:range];
            }
          }];
        }
        if (completionHandler) {
          completionHandler(nil);
        }
      }];
    } else {
      ASSERT(error);
      if (completionHandler) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
          completionHandler(error);
        }];
      }
    }
  }];
}

- (void)closeWithCompletionHandler:(void (^)(NSError *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if (!_openCount) {
    if (completionHandler) {
      completionHandler(NSError.alloc.init);
    }
    return;
  }
  --_openCount;
  if (_openCount) {
    if (completionHandler) {
      completionHandler(nil);
    }
    return;
  }
  NSString *contents = _contents.string;
  NSStringEncoding encoding;
  if (_explicitFileEncoding) {
    encoding = [_explicitFileEncoding unsignedIntegerValue];
  } else {
    encoding = NSUTF8StringEncoding;
  }
  __block NSError *error = nil;
  [self.project performAsynchronousFileAccessUsingBlock:^{
    [contents writeToURL:self.fileURL atomically:YES encoding:encoding error:&error];
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      if (completionHandler) {
        completionHandler(error);
      }
    }];
  }];
}

- (NSUInteger)length {
  ASSERT(_openCount);
  return _contents.length;
}

- (NSString *)string {
  ASSERT(_openCount);
  return _contents.string;
}

- (NSString *)substringWithRange:(NSRange)range {
  ASSERT(_openCount);
  return [_contents.string substringWithRange:range];
}

- (NSRange)lineRangeForRange:(NSRange)range {
  ASSERT(_openCount);
  return [_contents.string lineRangeForRange:range];
}

- (NSAttributedString *)attributedString {
  ASSERT(_openCount);
  return _contents.copy;
}

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range {
  ASSERT(_openCount);
  return [_contents attributedSubstringFromRange:range];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
  ASSERT(_openCount);
  return [_contents attribute:attrName atIndex:location effectiveRange:range];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit {
  ASSERT(_openCount);
  return [_contents attribute:attrName atIndex:location longestEffectiveRange:range inRange:rangeLimit];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
  ASSERT(_openCount);
  return [_contents attributesAtIndex:location effectiveRange:range];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit {
  ASSERT(_openCount);
  return [_contents attributesAtIndex:location longestEffectiveRange:range inRange:rangeLimit];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
  ASSERT(_openCount);
  // replacing an empty range with an empty string, no change required
  if (!range.length && !string.length) {
    return;
  }
  // replacing a substring with an equal string, no change required
  if ([string isEqualToString:[self substringWithRange:range]]) {
    return;
  }
  // a nil string can be passed to delete characters
  if (!string) {
    string = @"";
  }
  NSAttributedString *attributedString = [NSAttributedString.alloc initWithString:string attributes:self.theme.commonAttributes];
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:willReplaceCharactersInRange:withAttributedString:)]) {
      [presenter projectFile:self willReplaceCharactersInRange:range withAttributedString:attributedString];
    }
  }
  if (attributedString.length) {
    [_contents replaceCharactersInRange:range withAttributedString:attributedString];
  } else {
    [_contents deleteCharactersInRange:range];
  }
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:didReplaceCharactersInRange:withAttributedString:)]) {
      [presenter projectFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
    }
  }
  [_codeUnit reparseWithUnsavedContent:_contents.string];
}

- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)range {
  ASSERT(_openCount);
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:willChangeAttributesInRange:)]) {
      [presenter projectFile:self willChangeAttributesInRange:range];
    }
  }
  [_contents addAttribute:name value:value range:range];
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:didChangeAttributesInRange:)]) {
      [presenter projectFile:self didChangeAttributesInRange:range];
    }
  }
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range {
  ASSERT(_openCount);
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:willChangeAttributesInRange:)]) {
      [presenter projectFile:self willChangeAttributesInRange:range];
    }
  }
  [_contents addAttributes:attributes range:range];
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:didChangeAttributesInRange:)]) {
      [presenter projectFile:self didChangeAttributesInRange:range];
    }
  }
}

- (void)removeAttribute:(NSString *)name range:(NSRange)range {
  ASSERT(_openCount);
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:willChangeAttributesInRange:)]) {
      [presenter projectFile:self willChangeAttributesInRange:range];
    }
  }
  [_contents removeAttribute:name range:range];
  for (id<ACProjectFilePresenter>presenter in _presenters) {
    if ([presenter respondsToSelector:@selector(projectFile:didChangeAttributesInRange:)]) {
      [presenter projectFile:self didChangeAttributesInRange:range];
    }
  }
}

#pragma mark - Managing semantic content

- (TMSyntaxNode *)syntax {
  ASSERT(_openCount);
  return _codeUnit.syntax;
}

- (void)setSyntax:(TMSyntaxNode *)syntax {
  ASSERT(_openCount);
  _codeUnit.syntax = syntax;
}

- (void)setTheme:(TMTheme *)theme {
  if (theme == _theme) {
    return;
  }
  _theme = theme;
  if (_openCount) {
    [_contents setAttributes:theme.commonAttributes range:NSMakeRange(0, _contents.length)];
  }
}

- (NSArray *)symbolList {
  ASSERT(_openCount);
  return _codeUnit.symbolList;
}

- (NSArray *)diagnostics {
  ASSERT(_openCount);
  return _codeUnit.diagnostics;
}

- (void)qualifiedScopeIdentifierAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(NSString *))completionHandler {
  [_codeUnit qualifiedScopeIdentifierAtOffset:offset withCompletionHandler:completionHandler];
}

- (void)completionsAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(id<TMCompletionResultSet>))completionHandler {
  [_codeUnit completionsAtOffset:offset withCompletionHandler:completionHandler];
}

#pragma mark - Managing file bookmarks

- (NSArray *)bookmarks {
  return [_bookmarks allValues];
}

- (void)addBookmarkWithPoint:(id)point {
  ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self.project propertyListDictionary:nil file:self bookmarkPoint:point];
  [_bookmarks setObject:bookmark forKey:point];
  [self.project didAddBookmark:bookmark];
  [self.project updateChangeCount:UIDocumentChangeDone];
}

- (ACProjectFileBookmark *)bookmarkForPoint:(id)point {
  return [_bookmarks objectForKey:point];
}

#pragma mark - Internal Methods

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark {
  [self willChangeValueForKey:@"bookmarks"];
  [_bookmarks removeObjectForKey:bookmark.bookmarkPoint];
  [self.project didRemoveBookmark:bookmark];
  [self didChangeValueForKey:@"bookmarks"];
}

@end
