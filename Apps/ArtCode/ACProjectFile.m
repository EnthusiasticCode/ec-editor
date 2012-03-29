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

#import "FileBuffer.h"


static NSString * const _plistFileEncodingKey = @"fileEncoding";
static NSString * const _plistExplicitSyntaxKey = @"explicitSyntax";
static NSString * const _plistBookmarksKey = @"bookmarks";

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
}

@synthesize fileSize = _fileSize, explicitFileEncoding = _explicitFileEncoding, explicitSyntaxIdentifier = _explicitSyntaxIdentifier, fileBuffer = _codeFile;

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
  [self.project performAsynchronousFileAccessUsingBlock:^{
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfURL:self.fileURL encoding:encoding error:&error];
    if (fileContents) {
      [NSOperationQueue.mainQueue addOperationWithBlock:^{
        _codeFile = FileBuffer.alloc.init;
        [_codeFile replaceCharactersInRange:NSMakeRange(0, 0) withString:fileContents];
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
      completionHandler([[NSError alloc] init]);
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
  ASSERT(_codeFile);
  NSString *fileContents = _codeFile.string;
  NSStringEncoding encoding;
  if (_explicitFileEncoding) {
    encoding = [_explicitFileEncoding unsignedIntegerValue];
  } else {
    encoding = NSUTF8StringEncoding;
  }
  __block NSError *error = nil;
  [self.project performAsynchronousFileAccessUsingBlock:^{
    [fileContents writeToURL:self.fileURL atomically:YES encoding:encoding error:&error];
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      _codeFile = nil;
      if (completionHandler) {
        completionHandler(error);
      }
    }];
  }];
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

#pragma mark - Internal Methods

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark {
  [self willChangeValueForKey:@"bookmarks"];
  [_bookmarks removeObjectForKey:bookmark.bookmarkPoint];
  [self.project didRemoveBookmark:bookmark];
  [self didChangeValueForKey:@"bookmarks"];
}

@end
