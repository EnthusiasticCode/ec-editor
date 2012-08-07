//
//  TextFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TextFile.h"
#import <sys/xattr.h>

static NSString * const _contentKey = @"TextFileContent";
static NSString * const _bookmarksKey = @"TextFileBookmarks";

static const char * const _bookmarksXattrName = "TextFileBookmarks";
static size_t _bookmarksXattrMaxSize = 32 * 1024; // 32 kB

@implementation TextFile {
  NSMutableIndexSet *_bookmarks;
}

#pragma mark - UIDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  if (![contents isKindOfClass:[NSDictionary class]]) {
    return NO;
  }
  NSDictionary *contentsDictionary = contents;
  self.content = [[NSString alloc] initWithData:[contentsDictionary objectForKey:_contentKey] encoding:NSUTF8StringEncoding];
  id bookmarksData = [contentsDictionary objectForKey:_bookmarksKey];
  if (bookmarksData && bookmarksData != [NSNull null]) {
    self.bookmarks = [NSKeyedUnarchiver unarchiveObjectWithData:bookmarksData];
  }
  return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  id bookmarksData = [NSNull null];
  if (self.bookmarks) {
    bookmarksData = [NSKeyedArchiver archivedDataWithRootObject:self.bookmarks];
  }
  return @{ _contentKey : [self.content dataUsingEncoding:NSUTF8StringEncoding], _bookmarksKey : bookmarksData };
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)outError {
  NSData *content = [NSData dataWithContentsOfURL:url options:0 error:outError];
  if (!content) {
    return NO;
  }
  void *bookmarksBytes = malloc(_bookmarksXattrMaxSize);
  ssize_t bookmarksBytesCount = getxattr(url.path.fileSystemRepresentation, _bookmarksXattrName, bookmarksBytes, _bookmarksXattrMaxSize, 0, 0);
  id bookmarksData = [NSNull null];
  if (bookmarksBytesCount != -1) {
    bookmarksData = [NSData dataWithBytes:bookmarksBytes length:bookmarksBytesCount];
  }
  free(bookmarksBytes);
  __block BOOL success;
  dispatch_sync(dispatch_get_main_queue(), ^{
    success = [self loadFromContents:@{ _contentKey : content, _bookmarksKey : bookmarksData } ofType:nil error:outError];
  });
  return success;
}

- (BOOL)writeContents:(id)contents toURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation originalContentsURL:(NSURL *)originalContentsURL error:(NSError *__autoreleasing *)outError {
  if (![contents isKindOfClass:[NSDictionary class]]) {
    return NO;
  }
  NSDictionary *contentsDictionary = contents;
  NSData *fileContents = [contentsDictionary objectForKey:_contentKey];
  if (!fileContents) {
    return NO;
  }
  id bookmarksData = [contentsDictionary objectForKey:_bookmarksKey];
  BOOL success = [fileContents writeToURL:url options:NSDataWritingAtomic error:outError];
  if (!success) {
    return NO;
  }
  if (bookmarksData && bookmarksData != [NSNull null]) {
    success = !setxattr(url.path.fileSystemRepresentation, _bookmarksXattrName, [bookmarksData bytes], [bookmarksData length], 0, 0);
  }
  return success;
}

#pragma mark - Public Methods

- (void)setContent:(NSString *)content {
  if (content == _content) {
    return;
  }
  _content = content.copy;
  [self updateChangeCount:UIDocumentChangeDone];
  ASSERT(self.hasUnsavedChanges);
}

- (NSIndexSet *)bookmarks {
  if (!_bookmarks) {
    _bookmarks = [NSMutableIndexSet indexSet];
  }
  return _bookmarks.copy;
}

- (void)setBookmarks:(NSIndexSet *)bookmarks {
  if (bookmarks == _bookmarks) {
    return;
  }
  _bookmarks = bookmarks.mutableCopy;
}

- (BOOL)hasBookmarkAtLine:(NSUInteger)line {
  return [self.bookmarks containsIndex:line];
}

- (void)addBookmarkAtLine:(NSUInteger)line {
  [self willChangeValueForKey:@"bookmarks"];
  if (!_bookmarks) {
    _bookmarks = [NSMutableIndexSet indexSet];
  }
  [_bookmarks addIndex:line];
  [self didChangeValueForKey:@"bookmarks"];
  [self updateChangeCount:UIDocumentChangeDone];
}

- (void)removeBookmarkAtLine:(NSUInteger)line {
  [self willChangeValueForKey:@"bookmarks"];
  if (!_bookmarks) {
    _bookmarks = [NSMutableIndexSet indexSet];
  }
  [_bookmarks removeIndex:line];
  [self didChangeValueForKey:@"bookmarks"];
  [self updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - Helper Methods

+ (NSIndexSet *)bookmarksForFileURL:(NSURL *)fileURL {
  void *bookmarksBytes = malloc(_bookmarksXattrMaxSize);
  ssize_t bookmarksBytesCount = getxattr(fileURL.path.fileSystemRepresentation, _bookmarksXattrName, bookmarksBytes, _bookmarksXattrMaxSize, 0, 0);
  if (bookmarksBytesCount == -1) {
    free(bookmarksBytes);
    return nil;
  }
  NSIndexSet *bookmarks = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithBytesNoCopy:bookmarksBytes length:bookmarksBytesCount freeWhenDone:NO]];
  free(bookmarksBytes);
  return bookmarks;
}

@end
