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
}

@synthesize explicitFileEncoding = _explicitFileEncoding, explicitSyntaxIdentifier = _explicitSyntaxIdentifier;
@synthesize content = _content;

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

- (id)initWithProject:(ACProject *)project fileWrapper:(NSFileWrapper *)fileWrapper propertyListDictionary:(NSDictionary *)plistDictionary {
  self = [super initWithProject:project fileWrapper:fileWrapper propertyListDictionary:plistDictionary];
  if (!self) {
    return nil;
  }
  
  _bookmarks = NSMutableDictionary.alloc.init;
  
  _explicitFileEncoding = [plistDictionary objectForKey:_plistFileEncodingKey];
  _explicitSyntaxIdentifier = [plistDictionary objectForKey:_plistExplicitSyntaxKey];
  [[plistDictionary objectForKey:_plistBookmarksKey] enumerateKeysAndObjectsUsingBlock:^(id point, NSDictionary *bookmarkPlist, BOOL *stop) {
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
    
  self.fileWrapper = fileWrapper;
  
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

#pragma mark - File content

- (void)setContent:(NSString *)content {
  if (content == _content) {
    return;
  }
  
  _content = content;
  [self.project updateChangeCount:UIDocumentChangeDone];
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
