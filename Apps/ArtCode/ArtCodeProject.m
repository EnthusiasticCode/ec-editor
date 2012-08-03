//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeProject.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"
#import "NSString+Utilities.h"

#import "ArtCodeLocation.h"
#import "ArtCodeProjectSet.h"

#import "TextFile.h"


@interface ArtCodeProjectBookmark ()

+ (ArtCodeProjectBookmark *)bookmarkWithFileURL:(NSURL *)fileURL lineNumber:(NSUInteger)lineNumber;

@end

#pragma mark -

@implementation ArtCodeProject

#pragma mark - KVO overrides

+ (NSSet *)keyPathsForValuesAffectingFileURL {
  return [NSSet setWithObjects:@"name", @"projectSet.fileURL", nil];
}

+ (NSSet *)keyPathsForValuesAffectingLabelColor {
  return [NSSet setWithObject:@"labelColorString"];
}

#pragma mark - Public Methods

- (NSURL *)fileURL {
  return [[[self projectSet] fileURL] URLByAppendingPathComponent:[self name]];
}

- (UIColor *)labelColor {
  return [UIColor colorWithHexString:[self labelColorString]];
}

- (void)setLabelColor:(UIColor *)labelColor {
  [self setLabelColorString:[labelColor hexString]];
}

- (void)enumerateFilesWithBlock:(void (^)(NSURL *))block {
  ASSERT(block);
  NSURL *fileURL = self.fileURL;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableArray *files = [NSMutableArray array];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:fileURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
      for (NSURL *url in enumerator) {
        [files addObject:url];
      }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
      for (NSURL *url in files) {
        block(url);
      }
    });
  });
}

- (void)enumerateBookmarksWithBlock:(void (^)(ArtCodeProjectBookmark *))block {
  ASSERT(block);
  NSMutableArray *files = [NSMutableArray array];
  [self enumerateFilesWithBlock:^(NSURL *fileURL) {
    [files addObject:fileURL];
  }];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableArray *bookmarks = [[NSMutableArray alloc] init];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator prepareForReadingItemsAtURLs:files options:0 writingItemsAtURLs:nil options:0 error:NULL byAccessor:^(void (^completionHandler)(void)) {
      for (NSURL *fileURL in files) {
        __block NSIndexSet *fileBookmarks = nil;
        [fileCoordinator coordinateReadingItemAtURL:fileURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
          fileBookmarks = [TextFile bookmarksForFileURL:newURL];
        }];
        if (fileBookmarks) {
          [fileBookmarks enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [bookmarks addObject:[ArtCodeProjectBookmark bookmarkWithFileURL:fileURL lineNumber:idx]];
          }];
        }
      }
      completionHandler();
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
      for (ArtCodeProjectBookmark *bookmark in bookmarks) {
        block(bookmark);
      }
    });
  });
}

#pragma mark - Project-wide operations

- (void)duplicateWithCompletionHandler:(void (^)(ArtCodeProject *))completionHandler {
  [self _duplicateWithDuplicationNumber:1 completionHandler:completionHandler];
}

/// Recursive method to create a duplicated project
- (void)_duplicateWithDuplicationNumber:(NSUInteger)duplicationNumber completionHandler:(void (^)(ArtCodeProject *))completionHandler {
  __weak ArtCodeProject *this = self;
  [self.projectSet addNewProjectWithName:[self.name stringByAppendingFormat:@" (%u)", duplicationNumber] completionHandler:^(ArtCodeProject *project) {
    if (project) {
      // The project has been successfuly created, copying files
      NSFileCoordinator *fileCoordinator = [NSFileCoordinator new];
      [fileCoordinator coordinateReadingItemAtURL:this.fileURL options:0 writingItemAtURL:project.fileURL options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        NSFileManager *fileManager = [NSFileManager new];
        for (NSURL *url in [fileManager enumeratorAtURL:newReadingURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:NULL]) {
          [fileManager copyItemAtURL:url toURL:[newWritingURL URLByAppendingPathComponent:url.lastPathComponent] error:NULL];
        }
      }];
      if (completionHandler) {
        completionHandler(project);
      }
    } else {
      [this _duplicateWithDuplicationNumber:duplicationNumber + 1 completionHandler:completionHandler];
    }
  }];
}

@end

#pragma mark -

@implementation ArtCodeProjectBookmark

@synthesize fileURL = _fileURL, lineNumber = _lineNumber, name = _name;

+ (ArtCodeProjectBookmark *)bookmarkWithFileURL:(NSURL *)fileURL lineNumber:(NSUInteger)lineNumber {
  ASSERT(fileURL);
  ArtCodeProjectBookmark *bookmark = [[self alloc] init];
  bookmark->_fileURL = fileURL;
  bookmark->_lineNumber = lineNumber;
  bookmark->_name = [NSString stringWithFormat:@"%@: %d", fileURL.lastPathComponent, lineNumber];
  return bookmark;
}

@end