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
  NSMutableDictionary *_bookmarks;
  NSUInteger _openCount;
  NSMutableArray *_contentDisposables;
}

@synthesize fileSize = _fileSize, explicitFileEncoding = _explicitFileEncoding, explicitSyntaxIdentifier = _explicitSyntaxIdentifier, theme = _theme;
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
    [_bookmarks setObject:bookmark forKey:point];
    [self.project didAddBookmark:bookmark];
  }];
}

#pragma mark - ACProjectFileSystemItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent name:(NSString *)name {
  self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent name:name];
  if (!self) {
    return nil;
  }
  
  _bookmarks = NSMutableDictionary.alloc.init;
  _contentDisposables = NSMutableArray.alloc.init;
  
  if (![self readFromURL:self.fileURL error:NULL]) {
    return nil;
  }
  
  [self setPropertyListDictionary:plistDictionary];
    
  return self;
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (![super readFromURL:url error:error]) {
    return NO;
  }

  NSNumber *fileSize = nil;
  [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
  _fileSize = [fileSize unsignedIntegerValue];
  
//  // Read the contents if the file is open, otherwise just copy it over
//  if (_openCount) {
//    NSString *content = [NSString stringWithContentsOfURL:url encoding:self.fileEncoding error:NULL];
//    if (!content) {
//      _content = @"";
//    } else {
//      _content = content;
//    }
//  } else if (![url isEqual:self.fileURL]) {
//    NSFileManager *fileManager = NSFileManager.alloc.init;
//    if ([fileManager fileExistsAtPath:self.fileURL.path]) {
//      return [fileManager replaceItemAtURL:self.fileURL withItemAtURL:url backupItemName:nil options:0 resultingItemURL:NULL error:error];
//    } else {
//      return [fileManager copyItemAtURL:url toURL:self.fileURL error:error];
//    }
//  }
  
  return YES;
}

- (BOOL)writeToURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (![super writeToURL:url error:error]) {
    return NO;
  }
  
  // Make sure the file exists
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  if (![fileManager fileExistsAtPath:url.path]) {
    [fileManager createDirectoryAtURL:[url URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    if (![@"" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:error]) {
      return NO;
    }
  }
  
  // Write the contents if the file is open
  if (_content) {
    [_content writeToURL:url atomically:YES encoding:self.fileEncoding error:NULL];
  }
  
  return YES;
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
  completionHandler = [completionHandler copy];
  [self.project performAsynchronousFileAccessUsingBlock:^{
    NSError *error = nil;
    NSString *contents = nil;
    NSURL *fileURL = nil;
    ACProjectFile *outerStrongSelf = weakSelf;
    if (outerStrongSelf) {
      if (!theme) {
        theme = [TMTheme defaultTheme];
      }
      contents = [NSString.alloc initWithContentsOfURL:outerStrongSelf.fileURL encoding:encoding error:&error];
      fileURL = outerStrongSelf.fileURL;
    }
    if (!contents) {
      contents = @"";
    }
    [[[RACSubscribable startWithScheduler:self.project.codeIndexingScheduler block:^id(BOOL *success, NSError *__autoreleasing *racError) {
      TMUnit *codeUnit = [TMUnit.alloc initWithFileURL:fileURL index:nil];
      [codeUnit reparseWithUnsavedContent:contents];
      return codeUnit;
    }] deliverOn:RACScheduler.mainQueueScheduler] subscribeNext:^(id x) {
      ACProjectFile *innerStrongSelf = weakSelf;
      if (innerStrongSelf) {
        RACSubscribable *content = RACAble(innerStrongSelf, content);
        RACDisposable *disposable = [[content select:^id(id newContent) {
          return [NSAttributedString.alloc initWithString:newContent attributes:innerStrongSelf.theme.commonAttributes];
        }] toProperty:RAC_KEYPATH(innerStrongSelf, attributedContent) onObject:innerStrongSelf];
        [innerStrongSelf->_contentDisposables addObject:disposable];
        disposable = [content subscribeNext:^(id newContent) {
          [innerStrongSelf.codeUnit reparseWithUnsavedContent:newContent];
        }];
        [innerStrongSelf->_contentDisposables addObject:disposable];
        innerStrongSelf->_theme = theme;
        ++innerStrongSelf->_openCount;
        innerStrongSelf.content = contents;
        innerStrongSelf.codeUnit = x;
      }
      if (completionHandler) {
        completionHandler(nil);
      }
    }];
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
  NSString *contents = self.content;
  NSStringEncoding encoding;
  if (_explicitFileEncoding) {
    encoding = [_explicitFileEncoding unsignedIntegerValue];
  } else {
    encoding = NSUTF8StringEncoding;
  }
  
  for (RACDisposable *disposable in _contentDisposables) {
    [disposable dispose];
  }
  [_contentDisposables removeAllObjects];
  
  __block NSError *error = nil;
  completionHandler = [completionHandler copy];
  [self.project performAsynchronousFileAccessUsingBlock:^{
    // TODO: clean up this silly hack
    ++_openCount;
    [contents writeToURL:self.fileURL atomically:YES encoding:encoding error:&error];
    --_openCount;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      if (completionHandler) {
        completionHandler(error);
      }
    }];
  }];
}

- (void)setContent:(NSString *)content {
  ASSERT(_openCount);
  _content = content;
}

- (void)setAttributedContent:(NSAttributedString *)attributedContent {
  ASSERT(_openCount);
  _attributedContent = attributedContent;
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
    self.attributedContent = [self.attributedContent attributedStringBySettingAttributes:theme.commonAttributes range:NSMakeRange(0, self.attributedContent.length)];
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
