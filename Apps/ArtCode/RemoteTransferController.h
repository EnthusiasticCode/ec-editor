//
//  RemoteTransferController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MoveConflictController.h"

@protocol CKConnection;

@interface RemoteTransferController : MoveConflictController

/// Uploads the given local file URLs to specified connection.
- (void)uploadItemURLs:(NSArray *)itemURLs withConnection:(id<CKConnection>)connection toURL:(NSURL *)remoteURL completionHandler:(void(^)(id<CKConnection> connection))completionHandler;

/// This method will start the download process of the given items relative to the given remote URL from the connection to the local URL.
/// Items are an array of dictionaries as returned by the CKConnection.
- (void)downloadItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL toLocalURL:(NSURL *)localURL completionHandler:(void(^)(id<CKConnection> connection))completionHandler;

/// This method will start the process of deleting the given items. Folders will be deleted recursevly.
- (void)deleteItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL completionHandler:(void(^)(id<CKConnection> connection))completionHandler;

/// Returns a value that indicates if the started transfer has finished.
- (BOOL)isTransferFinished;

/// Cancels the current transfer if any and calls the completion handler passed to the transfer start method.
- (void)cancelCurrentTransfer;

@end
