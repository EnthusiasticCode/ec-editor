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

/// This method will start the download process of the given items relative to the given remote URL from the connection to the local URL.
/// The connection's delegate will be changed and it's responsability of the caller to set it back to it's original value.
/// Items are an array of dictionaries as returned by the CKConnection.
- (void)downloadItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL toLocalURL:(NSURL *)localURL completionHandler:(void(^)(id<CKConnection> connection))completionHandler;

/// Returns a value that indicates if the started transfer has finished.
- (BOOL)isTransferFinished;

/// Cancels the current transfer if any and calls the completion handler passed to the transfer start method.
- (void)cancelCurrentTransfer;

@end
