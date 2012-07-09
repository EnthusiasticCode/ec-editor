//
//  NSFileManager+FileCoordination.h
//  ArtCode
//
//  Created by Uri Baghin on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileCoordinator (CoordinatedFileManagement)

+ (void)coordinatedDeleteItemsAtURLs:(NSArray *)urls completionHandler:(void(^)(NSError *error))completionHandler;

+ (void)coordinatedMoveItemsAtURLS:(NSArray *)urls toURL:(NSURL *)url renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void(^)(NSError *error))completionHandler;

+ (void)coordinatedCopyItemsAtURLS:(NSArray *)urls toURL:(NSURL *)url renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void(^)(NSError *error))completionHandler;

+ (void)coordinatedDuplicateItemsAtURLS:(NSArray *)urls completionHandler:(void(^)(NSError *error))completionHandler;

@end
