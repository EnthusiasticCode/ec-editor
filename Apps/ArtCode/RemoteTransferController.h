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

typedef void(^RemoteTransferCompletionBlock)(id<CKConnection> connection, NSError *error);

enum RemoteSyncDirection {
    RemoteSyncDirectionLocalToRemote,
    RemoteSyncDirectionRemoteToLocal
};

enum RemoteSyncChangeDetermination {
    RemoteSyncChangeDeterminationModificationTime,
    RemoteSyncChangeDeterminationSize
};

/// An NSNumber with an int value of RemoteSyncDirection enum indicating if the syncronization should happen between remote to tocal.
extern NSString * const RemoteSyncOptionDirectionKey;
/// Indicates what to use to determine if a file has been modified.
extern NSString * const RemoteSyncOptionChangeDeterminationKey;

@interface RemoteTransferController : MoveConflictController

/// Uploads the given local file URLs to specified connection.
- (void)uploadItemURLs:(NSArray *)itemURLs toConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL completion:(RemoteTransferCompletionBlock)completionHandler;

/// This method will start the download process of the given items relative to the given remote URL from the connection to the local URL.
/// Items are an array of dictionaries as returned by the CKConnection.
- (void)downloadItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL toLocalURL:(NSURL *)localURL completion:(RemoteTransferCompletionBlock)completionHandler;

/// Syncronizes a local with a remote URL. Shows what is going to be moved before actually perform the operation.
- (void)syncLocalDirectoryURL:(NSURL *)localURL withConnection:(id<CKConnection>)connection remoteURL:(NSURL *)remoteURL options:(NSDictionary *)optionsDictionary completion:(RemoteTransferCompletionBlock)completionHandler;

/// This method will start the process of deleting the given items. Folders will be deleted recursevly.
- (void)deleteItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL completionHandler:(RemoteTransferCompletionBlock)completionHandler;

/// Returns a value that indicates if the started transfer has finished.
- (BOOL)isTransferFinished;

/// Cancels the current transfer if any and calls the completion handler passed to the transfer start method.
- (void)cancelCurrentTransfer;

@end
