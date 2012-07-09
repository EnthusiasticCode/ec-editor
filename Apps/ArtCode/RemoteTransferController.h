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

/// An NSNumber with an int value of RemoteSyncDirection enum indicating if the syncronization should happen between remote to tocal.
extern NSString * const RemoteSyncOptionDirectionKey;
/// Indicates what to use to determine if a file has been modified.
extern NSString * const RemoteSyncOptionChangeDeterminationKey;

typedef void(^RemoteTransferCompletionBlock)(id<CKConnection> connection, NSError *error);

/// Valid values for the RemoteSyncOptionDirectionKey option.
enum RemoteSyncDirection {
  RemoteSyncDirectionLocalToRemote,
  RemoteSyncDirectionRemoteToLocal
};

/// Valid values for the RemoteSyncOptionChangeDeterminationKey option.
enum RemoteSyncChangeDetermination {
  RemoteSyncChangeDeterminationModificationTime,
  RemoteSyncChangeDeterminationSize
};

/// Manages the transfer of items form a remote connection to a project folder.
/// NOTE: In the current implementation with ConnectionKit, the connection provided to any transfer method will have its delegate changed to handle callbacks; it will be restored uppon calling the completion block.
@interface RemoteTransferController : UIViewController <UITableViewDelegate, UITableViewDataSource>

#pragma mark Initiating a transfer

/// Uploads the given ACProjectFileSystemItem(s) to the specified connection.
- (void)uploadItemURLs:(NSArray *)itemURLs 
          toConnection:(id<CKConnection>)connection 
                  path:(NSString *)remotePath 
            completion:(RemoteTransferCompletionBlock)completionHandler;

/// This method will start the download process of the given item names relative to the given remote path from the connection to the local folder.
/// |items| are an array of dictionaries as returned by the CKConnection.
- (void)downloadConnectionItems:(NSArray *)items 
                 fromConnection:(id<CKConnection>)connection 
                           path:(NSString *)remotePath 
                 toDirectoryURL:(NSURL *)localDirectoryURL 
                     completion:(RemoteTransferCompletionBlock)completionHandler;

/// Syncronizes a local project folder with a remote path. 
/// Shows what is going to be moved before actually perform the operation.
- (void)synchronizeLocalDirectoryURL:(NSURL *)localDirectoryURL 
                      withConnection:(id<CKConnection>)connection 
                                path:(NSString *)remotePath 
                             options:(NSDictionary *)optionsDictionary 
                          completion:(RemoteTransferCompletionBlock)completionHandler;

/// This method will start the process of deleting the given items.
/// |items| are an array of dictionaries as returned by the CKConnection.
- (void)deleteConnectionItems:(NSArray *)items 
               fromConnection:(id<CKConnection>)connection 
                         path:(NSString *)remotePath 
                   completion:(RemoteTransferCompletionBlock)completionHandler;

#pragma mark Managing an ongoing transfer

/// Returns a value that indicates if the started transfer has finished.
- (BOOL)isTransferFinished;

/// Cancels the current transfer if any and calls the completion handler passed to the transfer start method.
- (void)cancelCurrentTransfer;

#pragma mark Interface Actions and Outlets

@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UITableView *conflictTableView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)doneAction:(id)sender;
- (IBAction)selectAllAction:(id)sender;
- (IBAction)selectNoneAction:(id)sender;

@end
