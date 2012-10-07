//
//  TextFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileSystemItem+TextFile.h"

static NSString * const _explicitSyntaxIdentifierKey = @"com.enthusiasticcode.artcode.TextFile.ExplicitSyntaxIdentifier";
static NSString * const _explicitEncodingKey = @"com.enthusiasticcode.artcode.TextFile.ExplicitEncoding";
static NSString * const _bookmarksKey = @"com.enthusiasticcode.artcode.TextFile.Bookmarks";

//static const char * const _bookmarksXattrName = ;
//static size_t _bookmarksXattrMaxSize = 32 * 1024; // 32 kB
//static const char * const _explicitSyntaxXattrName = ;
//static size_t _explicitSyntaxXattrMaxSize = 4 * 1024; // 4 kB

@implementation FileSystemItem (TextFile)

- (RACPropertySyncSubject *)explicitSyntaxIdentifier {
  return [self extendedAttributeForKey:_explicitSyntaxIdentifierKey];
}

- (RACPropertySyncSubject *)explicitEncoding {
  return [self extendedAttributeForKey:_explicitEncodingKey];
}

- (RACPropertySyncSubject *)bookmarks {
  return [self extendedAttributeForKey:_bookmarksKey];
}

//- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
//  if (![contents isKindOfClass:[NSDictionary class]]) {
//    return NO;
//  }
//  NSDictionary *contentsDictionary = contents;
//  self.content = [[NSString alloc] initWithData:[contentsDictionary objectForKey:_contentKey] encoding:NSUTF8StringEncoding];
//  id bookmarksData = [contentsDictionary objectForKey:_bookmarksKey];
//  if (bookmarksData && bookmarksData != [NSNull null]) {
//    self.bookmarks = [NSKeyedUnarchiver unarchiveObjectWithData:bookmarksData];
//  }
//  id explicitSyntaxData = [contentsDictionary objectForKey:_explicitSyntaxKey];
//  if (explicitSyntaxData && explicitSyntaxData != [NSNull null]) {
//    self.explicitSyntaxIdentifier = [NSKeyedUnarchiver unarchiveObjectWithData:explicitSyntaxData];
//  }
//  return YES;
//}
//
//- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
//  id bookmarksData = [NSNull null];
//  if (self.bookmarks) {
//    bookmarksData = [NSKeyedArchiver archivedDataWithRootObject:self.bookmarks];
//  }
//  id explicitSyntaxData = [NSNull null];
//  if (self.explicitSyntaxIdentifier) {
//    explicitSyntaxData = [NSKeyedArchiver archivedDataWithRootObject:self.explicitSyntaxIdentifier];
//  }
//  return @{ _contentKey : [self.content dataUsingEncoding:NSUTF8StringEncoding], _bookmarksKey : bookmarksData, _explicitSyntaxKey : explicitSyntaxData };
//}
//
//- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)outError {
//  NSData *content = [NSData dataWithContentsOfURL:url options:0 error:outError];
//  if (!content) {
//    return NO;
//  }
//  void *bookmarksBytes = malloc(_bookmarksXattrMaxSize);
//  ssize_t bookmarksBytesCount = getxattr(url.path.fileSystemRepresentation, _bookmarksXattrName, bookmarksBytes, _bookmarksXattrMaxSize, 0, 0);
//  id bookmarksData = [NSNull null];
//  if (bookmarksBytesCount != -1) {
//    bookmarksData = [NSData dataWithBytes:bookmarksBytes length:bookmarksBytesCount];
//  }
//  free(bookmarksBytes);
//  void *explicitSyntaxBytes = malloc(_explicitSyntaxXattrMaxSize);
//  ssize_t explicitSyntaxBytesCount = getxattr(url.path.fileSystemRepresentation, _explicitSyntaxXattrName, explicitSyntaxBytes, _explicitSyntaxXattrMaxSize, 0, 0);
//  id explicitSyntaxData = [NSNull null];
//  if (explicitSyntaxBytesCount != -1) {
//    explicitSyntaxData = [NSData dataWithBytes:explicitSyntaxBytes length:explicitSyntaxBytesCount];
//  }
//  free(explicitSyntaxBytes);
//  __block BOOL success;
//  dispatch_sync(dispatch_get_main_queue(), ^{
//    success = [self loadFromContents:@{ _contentKey : content, _bookmarksKey : bookmarksData, _explicitSyntaxKey : explicitSyntaxData } ofType:nil error:outError];
//  });
//  return success;
//}
//
//- (BOOL)writeContents:(id)contents toURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation originalContentsURL:(NSURL *)originalContentsURL error:(NSError *__autoreleasing *)outError {
//  if (![contents isKindOfClass:[NSDictionary class]]) {
//    return NO;
//  }
//  NSDictionary *contentsDictionary = contents;
//  NSData *fileContents = [contentsDictionary objectForKey:_contentKey];
//  if (!fileContents) {
//    return NO;
//  }
//  id bookmarksData = [contentsDictionary objectForKey:_bookmarksKey];
//  id explicitSyntaxData = [contentsDictionary objectForKey:_explicitSyntaxKey];
//  BOOL success = [fileContents writeToURL:url options:NSDataWritingAtomic error:outError];
//  if (!success) {
//    return NO;
//  }
//  if (bookmarksData && bookmarksData != [NSNull null]) {
//    success = !setxattr(url.path.fileSystemRepresentation, _bookmarksXattrName, [bookmarksData bytes], [bookmarksData length], 0, 0);
//    if (!success) {
//      return NO;
//    }
//  }
//  if (explicitSyntaxData && explicitSyntaxData != [NSNull null]) {
//    success = !setxattr(url.path.fileSystemRepresentation, _explicitSyntaxXattrName, [explicitSyntaxData bytes], [explicitSyntaxData length], 0, 0);
//    if (!success) {
//      return NO;
//    }
//  }
//  return YES;
//}

@end
