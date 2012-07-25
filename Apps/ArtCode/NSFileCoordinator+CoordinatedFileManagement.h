//
//  NSFileManager+FileCoordination.h
//  ArtCode
//
//  Created by Uri Baghin on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileCoordinator (CoordinatedFileManagement)

+ (void)coordinatedTouchItemAtURL:(NSURL *)url renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void(^)(NSError *error, NSURL *newURL))completionHandler;

+ (void)coordinatedMakeDirectoryAtURL:(NSURL *)url renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void(^)(NSError *error, NSURL *newURL))completionHandler;

+ (void)coordinatedDeleteItemsAtURLs:(NSArray *)urls completionHandler:(void(^)(NSError *error))completionHandler;

+ (void)coordinatedMoveItemsAtURLs:(NSArray *)urls toURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler;

+ (void)coordinatedCopyItemsAtURLs:(NSArray *)urls toURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler;

+ (void)coordinatedDuplicateItemsAtURLs:(NSArray *)urls completionHandler:(void(^)(NSError *error))completionHandler;

@end
