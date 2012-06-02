//
//  RemoteTransferController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteTransferController.h"
#import <Connection/CKConnectionRegistry.h>
#import "ArtCodeURL.h"
#import "ACProject.h"
#import "ACProjectFileSystemItem.h"
#import "ACProjectFolder.h"
#import "ACProjectFile.h"
#import "UIImage+AppStyle.h"
#import "NSURL+Utilities.h"

NSString * const RemoteSyncOptionDirectionKey = @"direction";
NSString * const RemoteSyncOptionChangeDeterminationKey = @"changeDetermination";

typedef enum {
  RemoteTransferUploadOperation,
  RemoteTransferDownloadOperation,
  RemoteTransferSynchronizationOperation,
  RemoteTransferDeleteOperation
} RemoteTransferOperation;

@interface RemoteTransferController ()

/// Gets a temporary directory URL and creates the directory if it doesn't exists.
/// This directory will be removed with all its content in viewDidDisappear:
- (NSURL *)_localTemporaryDirectoryURL;

/// Sets up the internal state to handle a new operation
- (void)_setupInternalStateForOperation:(RemoteTransferOperation)operation localFolder:(ACProjectFolder *)localFolder connection:(id<CKConnection>)connection path:(NSString *)remotePath items:(NSArray *)items completion:(RemoteTransferCompletionBlock)completionHandler;

/// Method used by synchronizeLocalProjectFolder:... to recursevly append files to upload in a syncronization
- (void)_syncLocalProjectFolder:(ACProjectFolder *)folder toRemotePath:(NSString *)remotePath;

/// Calls the completion handler with the given error, if error is nil, _transferError will be sent.
/// This method restores the connection's original delegate before calling the completion handler.
- (void)_callCompletionHandlerWithError:(NSError *)error;

/// Recursivelly queue uploads requests for the given item and subitems.
- (void)_uploadProjectItem:(ACProjectFileSystemItem *)item toConnection:(id<CKConnection>)connection path:(NSString *)remotePath;

@end

#pragma mark -

@implementation RemoteTransferController {
  // Connection related variables
  id<CKConnection> _connection;
  __weak NSObject *_connectionOriginalDelegate;
  NSString *_connectionPath;
  
  /// Working related variables
  NSArray *_items;
  NSMutableArray *_itemsConflicts;
  ACProjectFolder *_localFolder;
  RemoteTransferCompletionBlock _completionHandler;
  NSURL *_localTemporaryDirectoryURL;
  
  /// Indicates the operation that is being performed by the controller.
  RemoteTransferOperation _transferOperation;
  /// Dictionary of remote paths to the local project item to be handled according to _transferOperation
  NSMutableDictionary *_transfers;
  /// Dictionary of remote items to an NSNumber indicating the progress percent
  NSMutableDictionary *_transfersProgress;
  /// Number of trasfers started and completed, used to indicate completion percentage
  NSInteger _transfersStarted;
  NSInteger _transfersCompleted;
  NSError *_transferError;
  BOOL _transferCanceled;
  
  /// Synchronization specific flags
  BOOL _syncIsFromRemote;
  BOOL _syncUseFileSize;
}

@synthesize toolbar;
@synthesize conflictTableView;
@synthesize progressView;

#pragma mark - Object

- (id)init {
  self = [super initWithNibName:@"MoveConflictController" bundle:nil];
  if (!self)
    return nil;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [self init];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[self.toolbar.items objectAtIndex:0] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  [[self.toolbar.items objectAtIndex:1] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)viewDidDisappear:(BOOL)animated {
  _connection = nil;
  _connectionOriginalDelegate = nil;
  _connectionPath = nil;
  _items = nil;
  _itemsConflicts = nil;
  _localFolder = nil;
  _completionHandler = nil;
  _transfers = nil;
  _transfersProgress = nil;
  _transferError = nil;
  // Remove temp dir contents
  if (_localTemporaryDirectoryURL) {
    [[NSFileManager defaultManager] removeItemAtURL:_localTemporaryDirectoryURL error:NULL];
    _localTemporaryDirectoryURL = nil;
  }
  [super viewDidDisappear:animated];
}

#pragma mark - UITableView Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_itemsConflicts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const cellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
  id item = [_itemsConflicts objectAtIndex:indexPath.row];
  if ([item isKindOfClass:[NSDictionary class]]) {
    cell.textLabel.text = [(NSDictionary *)item objectForKey:cxFilenameKey];
    cell.detailTextLabel.text = nil;
    if ([(NSDictionary *)item objectForKey:NSFileType] == NSFileTypeDirectory) {
      cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    } else {
      cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[[(NSDictionary *)item objectForKey:cxFilenameKey] pathExtension]];
    }
  } else if ([item isKindOfClass:[NSString class]]) {
    cell.textLabel.text = [item lastPathComponent];
    cell.detailTextLabel.text = [item prettyPath];
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[item pathExtension]];
  } else {
    ASSERT([item isKindOfClass:[ACProjectFileSystemItem class]]);
    cell.textLabel.text = [item name];
    cell.detailTextLabel.text = [[item pathInProject] prettyPath];
    if ([(ACProjectFileSystemItem *)item type] == ACPFolder) {
      cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    } else {
      cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[[item name] pathExtension]];
    }
  }
  
  return cell;
}

#pragma mark - CKConnection

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error {
  ASSERT(con == _connection);
  ASSERT([dirPath hasPrefix:_connectionPath]);
  
  switch (_transferOperation) {
    case RemoteTransferUploadOperation: {
      // _transfers contains remote path to top ACProjectFileSystemItem to upload
      // We only need to check the existance of such items
      [_transfers enumerateKeysAndObjectsUsingBlock:^(NSString *uploadPath, ACProjectFileSystemItem *localItem, BOOL *stop) {
        BOOL exists = NO;
        for (NSDictionary *item in contents) {
          if ([[item objectForKey:cxFilenameKey] isEqualToString:[uploadPath lastPathComponent]]) {
            exists = YES;
            break;
          }
        }
        [self connection:(id<CKConnection>)con checkedExistenceOfPath:uploadPath pathExists:exists error:nil];
      }];
      break;
    }
      
    case RemoteTransferDownloadOperation: {
      // This codepath is reached if the download procedure recursed in a remote folder
      // Create the local temporary folder
      NSURL *localTemporaryURL = [[self _localTemporaryDirectoryURL] URLByAppendingPathComponent:[dirPath substringFromIndex:[_connectionPath length]]];
      [[NSFileManager defaultManager] createDirectoryAtURL:localTemporaryURL withIntermediateDirectories:YES attributes:nil error:NULL];
      // Append item to download queue
      for (NSDictionary *item in contents) {
        if ([item objectForKey:NSFileType] != NSFileTypeDirectory) {
          [_connection downloadFile:[dirPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]] toDirectory:localTemporaryURL.path overwrite:YES delegate:nil];
        } else {
          _transfersStarted++;
          [_connection changeToDirectory:[dirPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]]];
          [_connection directoryContents];
        }
      }
      // Inform of a completed transfer
      _transfersCompleted++;
      break;
    }
      
    case RemoteTransferSynchronizationOperation: {
      // _transfers are remote path to local project item
      // after the initial sync call, they represent the current status of the local content
      NSComparisonResult expectedToSync = _syncIsFromRemote ? NSOrderedAscending : NSOrderedDescending;
      for (NSDictionary *item in contents) {
        NSString *remoteItemPath = [dirPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]];
        ACProjectFileSystemItem *localItem = [_transfers objectForKey:remoteItemPath];
        if (localItem == nil) {
          if ( ! _syncIsFromRemote) {
            // local to remote: the remote item is present but the local is not, 
            // we will remove the orphaned file if needed.
            // TODO remove orphaned files?
            continue;
          } else {
            // remote to local: the local item is not present and it should be downloaded
            // add a placeholder local item to the _transfer list if it is not a directory
            // the placeholder will be created in the doneAction:
            if ([item objectForKey:NSFileType] != NSFileTypeDirectory) {
              [_transfers setObject:[dirPath substringFromIndex:[_connectionPath length]] forKey:remoteItemPath];
              continue;
            }
          }
        }
        // localItem here exists
        // if remote is a directory, no need to recreate it
        if ([item objectForKey:NSFileType] == NSFileTypeDirectory) {
          [_transfers removeObjectForKey:remoteItemPath];
          if (_syncIsFromRemote) {
            // remote to local: recursion in directory tree to check for other files not added in the first pass
            _transfersStarted++;
            [_connection changeToDirectory:remoteItemPath];
            [_connection directoryContents];
          }
          continue;
        }
        // Determine if the item should not be synced
#warning FIX
//        if (_syncUseFileSize && localItem.type == ACPFile) {
//          // remote to/from local: have the same hanling in this case
//          if ([(ACProjectFile *)localItem fileSize] == [[item objectForKey:NSFileSize] unsignedIntegerValue])
//            [_transfers removeObjectForKey:remoteItemPath];
//        } else {
//          // remote to local: local date later remote date means no sync
//          // local to remote: local date earlier remote date means no sync
//          if ([localItem.contentModificationDate compare:[item objectForKey:NSFileModificationDate]] != expectedToSync)
//            [_transfers removeObjectForKey:remoteItemPath];
//        }
      }
      
      // When all the remote items have been checked, we can complete a transfer
      _transfersCompleted++;
      if (_transfersCompleted == _transfersStarted) {
        if ([_transfers count] == 0) {
          // If no _transfers remain it means there is nothing to sync
          [self cancelCurrentTransfer];
        } else {
          // Present the UI to show what will be done
          _transfersStarted = _transfersCompleted = 0;
          self.progressView.progress = 0;
          self.conflictTableView.hidden = NO;
          self.toolbar.hidden = NO;
          self.progressView.hidden = YES;
          [self.conflictTableView setEditing:NO animated:NO];
          self.navigationItem.title = @"Files that will be synchronized";
          [_itemsConflicts setArray:[_transfers allKeys]];
          [self.conflictTableView reloadData];
        }
      } else {
        // If there are still subfolders to check, update progress bar
        [self.progressView setProgress:(float)_transfersCompleted / (float)_transfersStarted animated:YES];
      }
      break;
    }
      
    case RemoteTransferDeleteOperation: {
      // Recursion inside folders in the requested items to delete
      for (NSDictionary *item in contents) {
        if ([item objectForKey:NSFileType] != NSFileTypeDirectory) {
          [con deleteFile:[dirPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]]];
        } else {
          // Recurse
          [con changeToDirectory:[dirPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]]];
          [con directoryContents];
        }
      }
      // Remove directory that has been recursed into
      [(id<CKConnection>)con deleteDirectory:dirPath];
      break;
    }
  }
}

#pragma mark CKConnection Uploads

- (void)connection:(id <CKConnection>)con checkedExistenceOfPath:(NSString *)path pathExists:(BOOL)exists error:(NSError *)error {
  // This method will be called by the upload request via connection:didReceiveContent:ofPath:error:
  // _transfers contains remote upload path to local ACProjectFileSystemItem to upload
  ACProjectFileSystemItem *localItem = [_transfers objectForKey:path];
  ASSERT(localItem);
  
  if (!exists) {
    // Upload item on top directory
    [self _uploadProjectItem:localItem toConnection:con path:_connectionPath];
  } else {
    // TODO maybe move this when all possible uploads have finished?
    [_itemsConflicts addObject:localItem];
    self.conflictTableView.hidden = NO;
    self.toolbar.hidden = NO;
    self.progressView.hidden = YES;
    [self.conflictTableView reloadData];
    [self.conflictTableView setEditing:YES animated:NO];
    [self selectAllAction:nil];
    self.navigationItem.title = @"Select files to replace";
  }
}

- (void)connection:(id <CKPublishingConnection>)con uploadDidBegin:(NSString *)remotePath {
  ASSERT(con == _connection);
  _transfersStarted++;
  [_transfersProgress setObject:[NSNumber numberWithFloat:0] forKey:remotePath];
}

- (void)connection:(id <CKPublishingConnection>)con uploadDidFinish:(NSString *)remotePath error:(NSError *)error {
  ASSERT(con == _connection);
  
  // Handle error
  if (error) {
#if DEBUG
    NSLog(@"RemoteTransferController error: %@", [error localizedDescription]);
#endif
    _transferError = error;
    [self cancelCurrentTransfer];
    return;
  }
  
  // Increase transfer progress
  _transfersCompleted++;
  [_transfersProgress removeObjectForKey:remotePath];
  if ([self isTransferFinished]) {
    [self _callCompletionHandlerWithError:nil];
  }
}

- (void)connection:(id <CKConnection>)con upload:(NSString *)remotePath progressedTo:(NSNumber *)percent {
  ASSERT(con == _connection);
  
  [_transfersProgress setObject:percent forKey:remotePath];
  if (!self.progressView.isHidden) {
    __block float totalProgress = 0;
    [_transfersProgress enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *progress, BOOL *stop) {
      totalProgress += [progress floatValue];
    }];
    [self.progressView setProgress:(float)(totalProgress + _transfersCompleted * 100.0) / (float)(([_transfersProgress count] + _transfersCompleted) * 100.0) animated:YES];
  }
}

#pragma mark CKConnection Downloads

- (void)connection:(id <CKConnection>)con downloadDidBegin:(NSString *)remotePath {
  [self connection:con uploadDidBegin:remotePath];
}

- (void)connection:(id <CKConnection>)con downloadDidFinish:(NSString *)remotePath error:(NSError *)error {
  ASSERT(con == _connection);
  
  // Handle error
  if (error) {
    _transferError = error;
    [self cancelCurrentTransfer];
    return;
  }
  
  // Increase transfer progress
  _transfersCompleted++;
  [_transfersProgress removeObjectForKey:remotePath];
  if ([self isTransferFinished]) {
    // For both download and sync from remote, once finished downloading the local folder will be updated with the temporary directory 
    self.navigationItem.title = @"Finishing";
    self.progressView.progress = 0;
    [_localFolder updateWithContentsOfURL:[self _localTemporaryDirectoryURL] completionHandler:^(BOOL success) {
      [self.progressView setProgress:1 animated:YES];
      [self _callCompletionHandlerWithError:nil];
    }];
  }
}

- (void)connection:(id <CKConnection>)con download:(NSString *)path progressedTo:(NSNumber *)percent {
  [self connection:con upload:path progressedTo:percent];
}

#pragma mark CKConnection Cancel

- (void)connection:(id <CKConnection>)con didCancelTransfer:(NSString *)remotePath {
  [self connection:con uploadDidFinish:remotePath error:NULL];
}

#pragma mark CKConnection Delete

- (void)connection:(id <CKConnection>)con didDeleteDirectory:(NSString *)dirPath error:(NSError *)error {
  [self connection:con didDeleteFile:dirPath error:error];
}

- (void)connection:(id <CKPublishingConnection>)con didDeleteFile:(NSString *)path error:(NSError *)error {
  ASSERT(con == _connection);
  
  if (error) {
    _transferError = error;
    [self cancelCurrentTransfer];
    return;
  }
  
  _transfersCompleted++;
  [_transfersProgress removeObjectForKey:path];
  // TODO check with directories
  [self.progressView setProgress:(float)_transfersCompleted / (float)_transfersStarted animated:YES];
  if ([self isTransferFinished]) {
    [self _callCompletionHandlerWithError:nil];
  }
}

#pragma mark - Initiating a transfer

- (void)uploadProjectItems:(NSArray *)projectItems toConnection:(id<CKConnection>)connection path:(NSString *)remotePath completion:(RemoteTransferCompletionBlock)completionHandler {
  [self _setupInternalStateForOperation:RemoteTransferUploadOperation localFolder:nil connection:connection path:remotePath items:projectItems completion:completionHandler];
  
  for (ACProjectFileSystemItem *item in projectItems) {
    [_transfers setObject:item forKey:[_connectionPath stringByAppendingPathComponent:[item name]]];
  }
  [connection changeToDirectory:_connectionPath];
  [connection directoryContents];
}

- (void)downloadConnectionItems:(NSArray *)items fromConnection:(id<CKConnection>)connection path:(NSString *)remotePath toProjectFolder:(ACProjectFolder *)localProjectFolder completion:(RemoteTransferCompletionBlock)completionHandler {
  [self _setupInternalStateForOperation:RemoteTransferDownloadOperation localFolder:localProjectFolder connection:connection path:remotePath items:items completion:completionHandler];
  
  for (NSDictionary *item in items)
  {
    NSString *itemName = [item objectForKey:cxFilenameKey];
    
    // Check for conflicts in downloading location
    if ([localProjectFolder childWithName:itemName]) {
      [_itemsConflicts addObject:item];
      continue;
    }
    
    // Add to transfers
    NSString *itemPath = [_connectionPath stringByAppendingPathComponent:itemName];
    if ([item objectForKey:NSFileType] != NSFileTypeDirectory) {
      [_transfers setObject:[self _localTemporaryDirectoryURL] forKey:itemPath];
    } else {
      [_transfers setObject:[NSNull null] forKey:itemPath];
    }
  }
  
  // Show conflict resolution table if neccessary
  if ([_itemsConflicts count]) {
    self.conflictTableView.hidden = NO;
    self.toolbar.hidden = NO;
    self.progressView.hidden = YES;
    [self.conflictTableView reloadData];
    [self.conflictTableView setEditing:YES animated:NO];
    [self selectAllAction:nil];
    self.navigationItem.title = @"Select files to replace";
  } else {
    [self doneAction:nil];
  }
}

- (void)synchronizeLocalProjectFolder:(ACProjectFolder *)localProjectFolder withConnection:(id<CKConnection>)connection path:(NSString *)remotePath options:(NSDictionary *)optionsDictionary completion:(RemoteTransferCompletionBlock)completionHandler {
  [self _setupInternalStateForOperation:RemoteTransferSynchronizationOperation localFolder:localProjectFolder connection:connection path:remotePath items:nil completion:completionHandler];
  
  // Shows loading bar
  self.conflictTableView.hidden = YES;
  self.toolbar.hidden = YES;
  self.progressView.hidden = NO;
  self.navigationItem.title = @"Calculating differences";
  
  // Get synchronization options
  _syncIsFromRemote = [[optionsDictionary objectForKey:RemoteSyncOptionDirectionKey] boolValue];
  _syncUseFileSize = [[optionsDictionary objectForKey:RemoteSyncOptionChangeDeterminationKey] boolValue];
  
  // Populate transfers with items to synchronize 
  [self _syncLocalProjectFolder:localProjectFolder toRemotePath:_connectionPath];
  
  // If downloadin items initiate a single direcotry listing that will internally recurse on directories
  if (_syncIsFromRemote) {
    _transfersStarted++;
    [_connection changeToDirectory:_connectionPath];
    [_connection directoryContents];
  }
}

- (void)deleteConnectionItems:(NSArray *)items fromConnection:(id<CKConnection>)connection path:(NSString *)remotePath completion:(RemoteTransferCompletionBlock)completionHandler {
  // Terminate immediatly if no items needs to be removed
  if ([items count] == 0) {
    if (completionHandler)
      completionHandler(connection, nil);
    return;
  }
  
  [self _setupInternalStateForOperation:RemoteTransferDeleteOperation localFolder:nil connection:connection path:remotePath items:items completion:completionHandler];
  
  for (NSDictionary *item in items) {
    // Queue deletion
    if ([item objectForKey:NSFileType] != NSFileTypeDirectory) {
      _transfersStarted++;
      [connection deleteFile:[_connectionPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]]];
    } else {
      // Recursion
      [connection changeToDirectory:[_connectionPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]]];
      [connection directoryContents];
    }
  }
  
  // Show wait UI
  [self doneAction:nil];
}

#pragma mark - Managing an ongoing transfer

- (BOOL)isTransferFinished
{
  return _transferCanceled || (_transfersCompleted >= _transfersStarted && [_transfersProgress count] == 0 && [_itemsConflicts count] == 0);
}

- (void)cancelCurrentTransfer
{
  if (_transferCanceled)
    return;
  _transferCanceled = YES;
  [_connection cancelAll];
  if (_transferError || (_transfersCompleted >= _transfersStarted && [_transfersProgress count] == 0))
    [self _callCompletionHandlerWithError:_transferError];
}

#pragma mark - Interface Actions and Outlets

- (IBAction)doneAction:(id)sender {
  // Show loading UI
  self.conflictTableView.hidden = YES;
  self.toolbar.hidden = YES;
  self.progressView.hidden = NO;
  
  // Perform actions based on operation
  switch (_transferOperation) {
    case RemoteTransferUploadOperation: {
      self.navigationItem.title = @"Uploading";
      // uploads not conflicting in _transfers are already downloading
      // _itemConflicts contain a list of ACProjectFileSystemItem that may have been selected for replace
      for (NSIndexPath *indexPath in [self.conflictTableView indexPathsForSelectedRows]) {
        ACProjectFileSystemItem *item = [_itemsConflicts objectAtIndex:indexPath.row];
        [self _uploadProjectItem:item toConnection:_connection path:_connectionPath];
      }
      break;
    }
      
    case RemoteTransferDownloadOperation: {
      self.navigationItem.title = @"Downloading";
      // _transfers has the list of remote paths to local temp directory URL to download in.
      // _itemConflicts contains top level remote items that may have been selected to download.
      // Add resolved items to transfer list
      for (NSIndexPath *indexPath in [self.conflictTableView indexPathsForSelectedRows]) {
        NSDictionary *item = [_itemsConflicts objectAtIndex:indexPath.row];
        NSString *itemPath = [_connectionPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]];
        if ([item objectForKey:NSFileType] != NSFileTypeDirectory) {
          [_transfers setObject:[self _localTemporaryDirectoryURL] forKey:itemPath];
        } else {
          [_transfers setObject:[NSNull null] forKey:itemPath];
        }
      }
      // Start transfers
      // _transfers may contain NSNull values indicating that the remote path is infact a remote directory to recurse into
      [_transfers enumerateKeysAndObjectsUsingBlock:^(NSString *remotePath, NSURL* localDirecotryURL, BOOL *stop) {
        if (localDirecotryURL) {
          [_connection downloadFile:remotePath toDirectory:localDirecotryURL.path overwrite:YES delegate:nil];
        } else {
          ++_transfersStarted;
          [_connection changeToDirectory:remotePath];
          [_connection directoryContents];
        }
      }];
      // NOTE at this point all remote items will be added to the download queue,
      // the merge of downloaded items with local items will be done in connection:downloadDidFinish:error:
      break;
    }
      
    case RemoteTransferSynchronizationOperation: {
      self.navigationItem.title = @"Synchronizing";
      // Code path called by the user to commit a synch oreration.
      // _transfers contain all the remote path to local item/local path to be transfered
      // _syncIsFromRemote indicate the required direction of the transfer
      if (_syncIsFromRemote) {
        // Downloading items
        [_transfers enumerateKeysAndObjectsUsingBlock:^(NSString *remotePath, id itemOrlocalFolderPath, BOOL *stop) {
          ASSERT([remotePath hasPrefix:_connectionPath]);
          // localItem could be a string indicating the local path that should be created
          if ([itemOrlocalFolderPath isKindOfClass:[NSString class]]) {
            [[NSFileManager defaultManager] createDirectoryAtURL:[[self _localTemporaryDirectoryURL] URLByAppendingPathComponent:(NSString *)itemOrlocalFolderPath isDirectory:YES] withIntermediateDirectories:YES attributes:nil error:NULL];
            return;
          }
          // Rebuild the already existing temporary directory in which the item should be downloaded
          NSURL *syncDirectoryURL = [[self _localTemporaryDirectoryURL] URLByAppendingPathComponent:[[remotePath substringFromIndex:[_connectionPath length]] stringByDeletingLastPathComponent] isDirectory:YES];
          // the connection:downloadDidFinish:error: will handle the actual transfer from the temp file to the local project file
          [_connection downloadFile:remotePath toDirectory:[syncDirectoryURL path] overwrite:YES delegate:nil];
        }];
      } else {
        // Create all folders if needed
        [_transfers enumerateKeysAndObjectsUsingBlock:^(NSString *remotePath, ACProjectFileSystemItem *localItem, BOOL *stop) {
          if (localItem.type == ACPFolder) {
            [_connection createDirectoryAtPath:remotePath posixPermissions:nil];
          }
        }];
        // Uploading items
        [_transfers enumerateKeysAndObjectsUsingBlock:^(NSString *remotePath, ACProjectFileSystemItem *localItem, BOOL *stop) {
          if (localItem.type == ACPFile) {
            [self _uploadProjectItem:localItem toConnection:_connection path:[remotePath stringByDeletingLastPathComponent]];
          }
        }];
      }
      break;
    }
      
    case RemoteTransferDeleteOperation: {
      self.navigationItem.title = @"Deleting";
      break;
    }
  }
  
  // Conflicts are assumed to be resolved at this point
  _itemsConflicts = nil;
}

- (IBAction)selectAllAction:(id)sender {
  NSInteger count = [_itemsConflicts count];
  for (NSInteger i = 0; i < count; ++i) {
    [self.conflictTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
  }
}

- (IBAction)selectNoneAction:(id)sender {
  NSInteger count = [_itemsConflicts count];
  for (NSInteger i = 0; i < count; ++i) {
    [self.conflictTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES];
  }
}

#pragma mark - Private methods

- (void)_setupInternalStateForOperation:(RemoteTransferOperation)operation localFolder:(ACProjectFolder *)localFolder connection:(id<CKConnection>)connection path:(NSString *)remotePath items:(NSArray *)items completion:(RemoteTransferCompletionBlock)completionHandler {
  ASSERT(connection != nil);
  
  _connection = connection;
  _connectionOriginalDelegate = [connection delegate];
  [connection setDelegate:self];
  if ([remotePath hasPrefix:@"//"])
    remotePath = [remotePath substringFromIndex:1];
  _connectionPath = remotePath;
  
  _items = items;
  _itemsConflicts = [NSMutableArray new];
  _localFolder = localFolder;
  _completionHandler = [completionHandler copy];
  
  _transfers = [NSMutableDictionary dictionaryWithCapacity:[items count]];
  _transfersProgress = [NSMutableDictionary dictionaryWithCapacity:[items count]];
  _transfersStarted = 0;
  _transfersCompleted = 0;
  _transferCanceled = NO;
  _transferError = nil;
  _transferOperation = operation;
}

- (NSURL *)_localTemporaryDirectoryURL {
  if (_localTemporaryDirectoryURL)
    return _localTemporaryDirectoryURL;
  @synchronized (self) {
    _localTemporaryDirectoryURL = [NSURL temporaryDirectory];
    [[NSFileManager new] createDirectoryAtURL:_localTemporaryDirectoryURL withIntermediateDirectories:YES attributes:0 error:NULL];
  }
  return _localTemporaryDirectoryURL;
}

- (void)_syncLocalProjectFolder:(ACProjectFolder *)folder toRemotePath:(NSString *)remotePath
{
  ASSERT(_transfers);
  NSString *remoteItemPath = nil;
  for (ACProjectFileSystemItem *localItem in folder.children) {
    // Add to trasnfers as remote path to local project item
    remoteItemPath = [remotePath stringByAppendingPathComponent:localItem.name];
    [_transfers setObject:localItem forKey:remoteItemPath];
    // Recurse if folder
    if (localItem.type == ACPFolder) {
      [self _syncLocalProjectFolder:(ACProjectFolder *)localItem toRemotePath:remoteItemPath];
    }
  }
  
  // If sync is upload, initiate a directory listing for every subdirectory added
  if ( ! _syncIsFromRemote) {
    _transfersStarted++;
    [_connection changeToDirectory:remotePath];
    [_connection directoryContents];
  }
}

- (void)_callCompletionHandlerWithError:(NSError *)error {    
  [_connection setDelegate:_connectionOriginalDelegate];
  if (_completionHandler)
    _completionHandler(_connection, error ? error : _transferError);
}

- (void)_uploadProjectItem:(ACProjectFileSystemItem *)item toConnection:(id<CKConnection>)connection path:(NSString *)remotePath {
  if (item.type == ACPFolder) {
    remotePath = [remotePath stringByAppendingPathComponent:item.name];
    [connection createDirectoryAtPath:remotePath posixPermissions:nil];
    for (ACProjectFileSystemItem *subitem in [(ACProjectFolder *)item children]) {
      [self _uploadProjectItem:subitem toConnection:connection path:remotePath];
    }
  } else {
    NSURL *publishURL = [[self _localTemporaryDirectoryURL] URLByAppendingPathComponent:[remotePath substringFromIndex:[_connectionPath length]]];
    [item publishContentsToURL:publishURL completionHandler:^(BOOL success) {
      [connection uploadFileAtURL:publishURL toPath:remotePath posixPermissions:nil];
    }];
  }
}

@end

