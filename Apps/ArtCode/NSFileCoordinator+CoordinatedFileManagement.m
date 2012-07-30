//
//  NSFileManager+FileCoordination.m
//  ArtCode
//
//  Created by Uri Baghin on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSFileCoordinator+CoordinatedFileManagement.h"

@implementation NSFileCoordinator (CoordinatedFileManagement)

+ (void)coordinatedTouchItemAtURL:(NSURL *)url renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void (^)(NSError *, NSURL *))completionHandler {
  NSFileCoordinator *fileCoordinator = [[self alloc] init];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block NSError *error = nil;
    [fileCoordinator coordinateWritingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
      BOOL success = [[NSData data] writeToURL:newURL options:NSDataWritingAtomic error:&error];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
          completionHandler(nil, newURL);
        } else {
          completionHandler(error, nil);
        }
      });
    }];
  });
}

+ (void)coordinatedMakeDirectoryAtURL:(NSURL *)url renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void (^)(NSError *, NSURL *))completionHandler {
  ASSERT(!renameIfNeeded); // Not impemented
  NSFileCoordinator *fileCoordinator = [[self alloc] init];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block NSError *error = nil;
    [fileCoordinator coordinateWritingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      // Create new directory
      BOOL success = [fileManager createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:&error];
      // Send completion handler
      dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
          completionHandler(nil, newURL);
        } else {
          completionHandler(error, nil);
        }
      });
    }];
  });
}

+ (void)coordinatedDeleteItemsAtURLs:(NSArray *)urls completionHandler:(void (^)(NSError *))completionHandler {
  urls = urls.copy;
  NSFileCoordinator *fileCoordinator = [[self alloc] init];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block NSError *error = nil;
    [fileCoordinator prepareForReadingItemsAtURLs:nil options:0 writingItemsAtURLs:urls options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(void (^batchCompletionHandler)(void)){
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      for (NSURL *url in urls) {
        [fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL *newURL) {
          [fileManager removeItemAtURL:newURL error:&error];
        }];
      }
      batchCompletionHandler();
      dispatch_async(dispatch_get_main_queue(), ^{
        completionHandler(error);
      });
    }];
  });
}

+ (void)coordinatedMoveItemsAtURLs:(NSArray *)sourceURLs toURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler {
  sourceURLs = sourceURLs.copy;
  NSFileCoordinator *fileCoordinator = [[self alloc] init];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableArray *destinationURLs = [NSMutableArray arrayWithCapacity:sourceURLs.count];
    for (NSURL *sourceURL in sourceURLs) {
      [destinationURLs addObject:[url URLByAppendingPathComponent:sourceURL.lastPathComponent]];
    }
    [destinationURLs addObject:url];
    __block NSError *error = nil;
    [fileCoordinator prepareForReadingItemsAtURLs:sourceURLs options:0 writingItemsAtURLs:destinationURLs options:0 error:&error byAccessor:^(void (^batchCompletionHandler)(void)){
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      [fileManager createDirectoryAtURL:[destinationURLs lastObject] withIntermediateDirectories:YES attributes:nil error:NULL];
      [sourceURLs enumerateObjectsUsingBlock:^(NSURL *sourceURL, NSUInteger idx, BOOL *stop) {
        NSURL *destinationURL = [destinationURLs objectAtIndex:idx];
        [fileCoordinator coordinateReadingItemAtURL:sourceURL options:0 writingItemAtURL:destinationURL options:0 error:&error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
          [fileManager moveItemAtURL:newReadingURL toURL:newWritingURL error:&error];
          [fileCoordinator itemAtURL:newReadingURL didMoveToURL:newWritingURL];
        }];
      }];
      batchCompletionHandler();
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(error);
    });
  });
}

+ (void)coordinatedCopyItemsAtURLs:(NSArray *)sourceURLs toURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler {
  sourceURLs = sourceURLs.copy;
  NSFileCoordinator *fileCoordinator = [[self alloc] init];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableArray *destinationURLs = [NSMutableArray arrayWithCapacity:sourceURLs.count];
    for (NSURL *sourceURL in sourceURLs) {
      [destinationURLs addObject:[url URLByAppendingPathComponent:sourceURL.lastPathComponent]];
    }
    [destinationURLs addObject:url];
    __block NSError *error = nil;
    [fileCoordinator prepareForReadingItemsAtURLs:sourceURLs options:0 writingItemsAtURLs:destinationURLs options:0 error:&error byAccessor:^(void (^batchCompletionHandler)(void)){
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      [fileManager createDirectoryAtURL:[destinationURLs lastObject] withIntermediateDirectories:YES attributes:nil error:NULL];
      [sourceURLs enumerateObjectsUsingBlock:^(NSURL *sourceURL, NSUInteger idx, BOOL *stop) {
        NSURL *destinationURL = [destinationURLs objectAtIndex:idx];
        [fileCoordinator coordinateReadingItemAtURL:sourceURL options:0 writingItemAtURL:destinationURL options:0 error:&error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
          [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
          [fileCoordinator itemAtURL:newReadingURL didMoveToURL:newWritingURL];
        }];
      }];
      batchCompletionHandler();
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(error);
    });
  });
}

+ (void)coordinatedDuplicateItemsAtURLs:(NSArray *)urls completionHandler:(void(^)(NSError *error))completionHandler {
  UNIMPLEMENTED_VOID();
}

@end
