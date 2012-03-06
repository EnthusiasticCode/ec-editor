//
//  RemoteTransferController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteTransferController.h"
#import "UIImage+AppStyle.h"
#import "ArtCodeURL.h"
#import <Connection/CKConnectionRegistry.h>

NSString * const RemoteSyncOptionDirectionKey = @"direction";
NSString * const RemoteSyncOptionChangeDeterminationKey = @"changeDetermination";

@interface RemoteTransferController ()

- (void)_callCompletionHandlerWithError:(NSError *)error;

/// Method used to recursevly append files to upload in a syncronization
- (void)_syncLocalURL:(NSURL *)local toRemotePath:(NSString *)remote;

@end

@implementation RemoteTransferController {
    id<CKConnection> _connection;
    NSArray *_items;
    NSURL *_remoteURL;
    NSURL *_localURL;
    RemoteTransferCompletionBlock _completionHandler;
    __weak NSObject *_originalDelegate;
    
    /// Dictionary of remote paths to the local URL to be uploaded there
    NSMutableDictionary *_uploads;
    NSMutableDictionary *_syncs;
    BOOL _syncIsFromRemote;
    BOOL _syncUseFileSize;
    
    /// Dictionary of remote items to an NSNumber indicating the progress percent
    NSMutableDictionary *_transfersProgress;
    NSUInteger _transfersStarted;
    NSInteger _transfersCompleted;
    NSError *_transferError;
    BOOL _transferCanceled;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _uploads = nil;
    _syncs = nil;
    _transferCanceled = NO;
}

- (void)viewDidUnload
{
    _connection = nil;
    _items = nil;
    _remoteURL = nil;
    _localURL = nil;
    _completionHandler = nil;
    _uploads = nil;
    _transfersProgress = nil;
    _transferError = nil;
    [super viewDidUnload];
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    id item = [self.conflictURLs objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[NSDictionary class]])
    {
        cell.textLabel.text = [item objectForKey:cxFilenameKey];
        cell.detailTextLabel.text = nil;
        if ([item objectForKey:NSFileType] == NSFileTypeDirectory)
            cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
        else
            cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[[item objectForKey:cxFilenameKey] pathExtension]];
    }
    else
    {
        cell.textLabel.text = [[self.conflictURLs objectAtIndex:indexPath.row] lastPathComponent];
        cell.detailTextLabel.text = [[self.conflictURLs objectAtIndex:indexPath.row] prettyPath];
        NSString *ext = [cell.textLabel.text pathExtension];
        if ([ext length])
            cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:ext];
        else
            cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    }
    
    return cell;
}

#pragma mark - Connection

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error
{
    if (_uploads != nil)
    {
        // Implementation to substitute non working checkExistenceOfPath:
        [_uploads enumerateKeysAndObjectsUsingBlock:^(NSString *uploadPath, NSURL *localURL, BOOL *stop) {
            // Check for existance
            BOOL exists = NO;
            for (NSDictionary *item in contents)
            {
                if ([[item objectForKey:cxFilenameKey] isEqualToString:[uploadPath lastPathComponent]])
                {
                    exists = YES;
                    break;
                }
            }
            [self connection:(id<CKConnection>)con checkedExistenceOfPath:uploadPath pathExists:exists error:nil];
        }];
    }
    else if (_syncs != nil)
    {
        NSComparisonResult expectedToSync = _syncIsFromRemote ? NSOrderedAscending : NSOrderedDescending;
        NSNumber *fileSize = nil;
        NSDate *fileModificationDate = nil;
        for (NSDictionary *item in contents)
        {
            NSString *remoteItemPath = [dirPath stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]];
            NSURL *localItemURL = [_syncs objectForKey:remoteItemPath];
            if (localItemURL == nil)
            {
                if ( ! _syncIsFromRemote)
                {
                    // local to remote: if no local file, skip
                    // TODO remove orphaned files?
                    continue;
                }
                else
                {
                    ECASSERT([remoteItemPath hasPrefix:_remoteURL.path]);
                    localItemURL = [_localURL URLByAppendingPathComponent:[remoteItemPath substringFromIndex:[_remoteURL.path length]]];
                    // remote to local: add item to be downloaded if not a directory
                    if ([item objectForKey:NSFileType] != NSFileTypeDirectory)
                    {
                        [_syncs setObject:localItemURL forKey:remoteItemPath];
                        continue;
                    }
                }
            }
            // if remote is a directory, no need to recreate it
            if ([item objectForKey:NSFileType] == NSFileTypeDirectory)
            {
                [_syncs removeObjectForKey:remoteItemPath];
                if (_syncIsFromRemote)
                {
                    // remote to local: recursion in directory tree
                    _transfersStarted++;
                    [_connection changeToDirectory:remoteItemPath];
                    [_connection directoryContents];
                }
                continue;
            }
            // Determine if the item should not be synced
            if (_syncUseFileSize)
            {
                // remote to/from local: have the same hanling in this case
                [localItemURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
                if ([fileSize isEqualToNumber:[item objectForKey:NSFileSize]])
                    [_syncs removeObjectForKey:remoteItemPath];
            }
            else
            {
                // remote to local: local date later remote date means no sync
                // local to remote: local date earlier remote date means no sync
                [localItemURL getResourceValue:&fileModificationDate forKey:NSURLContentModificationDateKey error:NULL];
                if ([fileModificationDate compare:[item objectForKey:NSFileModificationDate]] != expectedToSync)
                    [_syncs removeObjectForKey:remoteItemPath];
            }
        }
        
        _transfersCompleted++;
        if (_transfersCompleted == _transfersStarted)
        {
            if ([_syncs count] == 0)
            {
                [self cancelCurrentTransfer];
            }
            else 
            {
                _transfersStarted = _transfersCompleted = 0;
                self.progressView.progress = 0;
                self.conflictTableView.hidden = NO;
                self.toolbar.hidden = NO;
                self.progressView.hidden = YES;
                [self.conflictTableView setEditing:NO animated:NO];
                self.navigationItem.title = @"Files that will be synchronized";
                [self.conflictURLs setArray:[_syncs allKeys]];
                [self.conflictTableView reloadData];
            }
        }
        else 
        {
            [self.progressView setProgress:(float)_transfersCompleted / (float)_transfersStarted animated:YES];
        }
    }
}

#pragma mark - Connection Uploads

- (void)connection:(id <CKConnection>)con checkedExistenceOfPath:(NSString *)path pathExists:(BOOL)exists error:(NSError *)error
{
    // This method will be called by the upload request
    NSURL *localURL = [_uploads objectForKey:path];
    ECASSERT(localURL);
        
    if (!exists)
    {
        // Check for local file existance
        BOOL isDirectory = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:localURL.path isDirectory:&isDirectory])
            return; // TODO raise error?
        
        // Start the upload if no conflicts
        if (isDirectory)
            [con recursivelyUpload:localURL.path to:_remoteURL.path];
        else
            [con uploadFileAtURL:localURL toPath:path posixPermissions:nil];
    }
    else
    {
        [self.conflictURLs addObject:path];
        self.conflictTableView.hidden = NO;
        self.toolbar.hidden = NO;
        self.progressView.hidden = YES;
        [self.conflictTableView reloadData];
        [self.conflictTableView setEditing:YES animated:NO];
        [self selectAllAction:nil];
        self.navigationItem.title = @"Select files to replace";
    }
}

- (void)connection:(id <CKPublishingConnection>)con uploadDidBegin:(NSString *)remotePath
{
    _transfersStarted++;
    [_transfersProgress setObject:[NSNumber numberWithFloat:0] forKey:remotePath];
}

- (void)connection:(id <CKPublishingConnection>)con uploadDidFinish:(NSString *)remotePath error:(NSError *)error
{
    if (error)
    {
        _transferError = error;
        [self cancelCurrentTransfer];
        return;
    }
        
    _transfersCompleted++;
    [_transfersProgress removeObjectForKey:remotePath];
    if ([self isTransferFinished])
    {
        [self _callCompletionHandlerWithError:nil];
    }
}

- (void)connection:(id <CKConnection>)con upload:(NSString *)remotePath progressedTo:(NSNumber *)percent
{
    [_transfersProgress setObject:percent forKey:remotePath];
    if (!self.progressView.isHidden)
    {
        __block float totalProgress = 0;
        [_transfersProgress enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *progress, BOOL *stop) {
            totalProgress += [progress floatValue];
        }];
        [self.progressView setProgress:(totalProgress + _transfersCompleted * 100.0) / (([_transfersProgress count] + _transfersCompleted) * 100.0) animated:YES];
    }
}

#pragma mark - Connection Downloads

- (void)connection:(id <CKConnection>)con downloadDidBegin:(NSString *)remotePath
{
    [self connection:con uploadDidBegin:remotePath];
}

- (void)connection:(id <CKConnection>)con downloadDidFinish:(NSString *)remotePath error:(NSError *)error
{
    [self connection:con uploadDidFinish:remotePath error:error];
}

- (void)connection:(id <CKConnection>)con download:(NSString *)path progressedTo:(NSNumber *)percent
{
    [self connection:con upload:path progressedTo:percent];
}

#pragma mark - Connection Cancel Transfer

- (void)connection:(id <CKConnection>)con didCancelTransfer:(NSString *)remotePath
{
    [self connection:con uploadDidFinish:remotePath error:NULL];
}

#pragma mark - Connection Delete Items

- (void)connection:(id <CKConnection>)con didDeleteDirectory:(NSString *)dirPath error:(NSError *)error
{
    [self connection:con didDeleteFile:dirPath error:error];
}

- (void)connection:(id <CKPublishingConnection>)con didDeleteFile:(NSString *)path error:(NSError *)error
{
    _transfersCompleted++;
    [_transfersProgress removeObjectForKey:path];
    // TODO check with directories
    [self.progressView setProgress:(float)_transfersCompleted / (float)_transfersStarted animated:YES];
    if ([self isTransferFinished])
    {
        [self _callCompletionHandlerWithError:nil];
    }
}

#pragma mark - Public methods

- (BOOL)isTransferFinished
{
    return _transferCanceled || (_transfersCompleted >= _transfersStarted && [_transfersProgress count] == 0 && [self.conflictURLs count] == 0);
}

- (void)cancelCurrentTransfer
{
    if (_transferCanceled)
        return;
    _transferCanceled = YES;
    [_connection cancelAll];
    if (_transfersCompleted >= _transfersStarted && [_transfersProgress count] == 0)
        [self _callCompletionHandlerWithError:_transferError];
}

- (void)uploadItemURLs:(NSArray *)itemURLs toConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL completion:(RemoteTransferCompletionBlock)completionHandler
{
    ECASSERT(connection != nil);
    
    // Reset progress
    self.progressView.progress = 0;
    _transfersStarted = 0;
    _transfersCompleted = 0;
    
    // Change the connection's delegate
    _originalDelegate = [connection delegate];
    [connection setDelegate:self];
    
    _items = itemURLs;
    _connection = connection;
    _remoteURL = remoteURL;
    _completionHandler = [completionHandler copy];
    
    _uploads = [NSMutableDictionary dictionaryWithCapacity:[itemURLs count]];
    _transfersProgress = [NSMutableDictionary dictionaryWithCapacity:[itemURLs count]];
    
    NSString *remotePath = [remoteURL path];
    for (NSURL *item in itemURLs)
    {
        NSString *uploadPath = [remotePath stringByAppendingPathComponent:[item lastPathComponent]];
        [_uploads setObject:item forKey:uploadPath];
//        [connection checkExistenceOfPath:uploadPath];
    }
    [connection changeToDirectory:remotePath];
    [connection directoryContents];
}

- (void)downloadItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL toLocalURL:(NSURL *)localURL completion:(RemoteTransferCompletionBlock)completionHandler
{
    ECASSERT(connection != nil);
    
    // Reset progress
    self.progressView.progress = 0;
    _transfersStarted = 0;
    _transfersCompleted = 0;
    
    // Change the connection's delegate
    _originalDelegate = [connection delegate];
    [connection setDelegate:self];

    // First pass to download items that are not conflicting with local files
    _transfersProgress = [NSMutableDictionary dictionaryWithCapacity:[items count]];
    _items = items;
    _connection = connection;
    _remoteURL = remoteURL;
    _localURL = localURL;
    _completionHandler = [completionHandler copy];
    for (NSDictionary *item in items)
    {
        NSString *destinationPath = [localURL.path stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
        {
            [self.conflictURLs addObject:item];
            continue;
        }
        
        if ([item objectForKey:NSFileType] == NSFileTypeDirectory)
        {
            [connection recursivelyDownload:[[remoteURL path] stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]] to:[localURL path] overwrite:YES];
        }
        else
        {
            [connection downloadFile:[[remoteURL path] stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]] toDirectory:[localURL path] overwrite:YES delegate:nil];
        }
    }
    
    // Show conflict resolution table if neccessary
    if ([self.conflictURLs count])
    {
        self.conflictTableView.hidden = NO;
        self.toolbar.hidden = NO;
        self.progressView.hidden = YES;
        [self.conflictTableView reloadData];
        [self.conflictTableView setEditing:YES animated:NO];
        [self selectAllAction:nil];
        self.navigationItem.title = @"Select files to replace";
    }
    else
    {
        self.conflictTableView.hidden = YES;
        self.toolbar.hidden = YES;
        self.progressView.hidden = NO;
        self.navigationItem.title = @"Downloading";
    }
    
    // Terminate or prepare to handle transfers
    if ([items count] == 0 && [self.conflictURLs count] == 0)
    {
        [connection setDelegate:_originalDelegate];
        if (completionHandler)
            completionHandler(connection, nil);
    }
}

- (void)syncLocalDirectoryURL:(NSURL *)localURL withConnection:(id<CKConnection>)connection remoteURL:(NSURL *)remoteURL options:(NSDictionary *)optionsDictionary completion:(RemoteTransferCompletionBlock)completionHandler
{
    ECASSERT(connection != nil);
    
    // Reset progress
    self.progressView.progress = 0;
    _transfersStarted = 0;
    _transfersCompleted = 0;
    
    // Change the connection's delegate
    _originalDelegate = [connection delegate];
    [connection setDelegate:self];
    
    _connection = connection;
    _localURL = localURL;
    _remoteURL = remoteURL;
    _completionHandler = [completionHandler copy];
    
    // Get options
    _syncIsFromRemote = [[optionsDictionary objectForKey:RemoteSyncOptionDirectionKey] boolValue];
    _syncUseFileSize = [[optionsDictionary objectForKey:RemoteSyncOptionChangeDeterminationKey] boolValue];
    _syncs = [NSMutableDictionary new];
    
    [self _syncLocalURL:localURL toRemotePath:remoteURL.path];
    if (_syncIsFromRemote)
    {
        _transfersStarted++;
        [_connection changeToDirectory:remoteURL.path];
        [_connection directoryContents];
    }

    self.conflictTableView.hidden = YES;
    self.toolbar.hidden = YES;
    self.progressView.hidden = NO;
    self.navigationItem.title = @"Calculating differences";
}

- (void)deleteItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL completionHandler:(RemoteTransferCompletionBlock)completionHandler
{
    ECASSERT(connection != nil);
    
    // Terminate immediatly if no items needs to be removed
    if ([items count] == 0)
    {
        if (completionHandler)
            completionHandler(connection, nil);
        return;
    }
    
    // Reset progress
    self.progressView.progress = 0;
    _transfersStarted = 0;
    _transfersCompleted = 0;
    
    // Change the connection's delegate
    _originalDelegate = [connection delegate];
    [connection setDelegate:self];
    
    _connection = connection;
    _remoteURL = remoteURL;
    _completionHandler = [completionHandler copy];
    _transfersProgress = [NSMutableDictionary dictionaryWithCapacity:[items count]];
    for (NSDictionary *item in items)
    {
        _transfersStarted++;
        NSString *remoteItemPath = [[remoteURL path] stringByAppendingPathComponent:[item objectForKey:cxFilenameKey]];
        if ([item objectForKey:NSFileType] == NSFileTypeDirectory)
        {
            [connection recursivelyDeleteDirectory:remoteItemPath];
        }
        else
        {
            [connection deleteFile:remoteItemPath];
        }
        [_transfersProgress setObject:[NSNull null] forKey:remoteItemPath];
    }
    
    // Prepare UI
    self.conflictTableView.hidden = YES;
    self.toolbar.hidden = YES;
    self.progressView.hidden = NO;
    self.navigationItem.title = @"Deleting";
}

#pragma mark - Actions

- (void)replaceAction:(id)sender
{
    if (_syncs)
    {
        [_syncs enumerateKeysAndObjectsUsingBlock:^(NSString *remotePath, NSURL *localURL, BOOL *stop) {
            if (_syncIsFromRemote)
            {
                // remote to local: create local directory to be sure; download files
                NSString *localDirecotryPath = [localURL.path stringByDeletingLastPathComponent];
                [[NSFileManager defaultManager] createDirectoryAtPath:localDirecotryPath withIntermediateDirectories:YES attributes:nil error:NULL];
                [_connection downloadFile:remotePath toDirectory:localDirecotryPath overwrite:YES delegate:nil];
            }
            else
            {
                NSNumber *isDirectory = nil;
                [localURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
                if ([isDirectory boolValue])
                {
                    [_connection createDirectoryAtPath:remotePath posixPermissions:nil];
                }
                else
                {
                    [_connection uploadFileAtURL:localURL toPath:remotePath posixPermissions:nil];
                }
            }
        }];
    }
    else if (_uploads)
    {
        for (NSIndexPath *indexPath in [self.conflictTableView indexPathsForSelectedRows])
        {
            NSURL *localURL = [_uploads objectForKey:[self.conflictURLs objectAtIndex:indexPath.row]];
            
            // Check for file existance
            BOOL isDirectory = NO;
            if (![[NSFileManager defaultManager] fileExistsAtPath:localURL.path isDirectory:&isDirectory])
                continue;
            
            // Start the upload if no conflicts
            if (isDirectory)
                [_connection recursivelyUpload:localURL.path to:_remoteURL.path];
            else
                [_connection uploadFileAtURL:localURL toPath:_remoteURL.path posixPermissions:nil];
        }
    }
    else
    {
        for (NSIndexPath *indexPath in [self.conflictTableView indexPathsForSelectedRows])
        {
            NSDictionary *item = [self.conflictURLs objectAtIndex:indexPath.row];
            if ([item objectForKey:NSFileType] == NSFileTypeDirectory)
            {
                [_connection recursivelyDownload:[item objectForKey:cxFilenameKey] to:[_localURL path] overwrite:YES];
            }
            else
            {
                [_connection downloadFile:[item objectForKey:cxFilenameKey] toDirectory:[_localURL path] overwrite:YES delegate:nil];
            }
        }
    }
    [self keepOriginalAction:sender];
}

- (void)keepOriginalAction:(id)sender
{
    [super keepOriginalAction:sender];
    if ([self isTransferFinished])
    {
        [self _callCompletionHandlerWithError:nil];
    }
    else
    {
        // Reveal progress bar if there are still transfers to be completed
        self.conflictTableView.hidden = YES;
        self.toolbar.hidden = YES;
        self.progressView.hidden = NO;
        if (_syncs)
            self.navigationItem.title = @"Synchronizing";
        else if (_uploads)
            self.navigationItem.title = @"Uploading";
        else
            self.navigationItem.title = @"Downloading";
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.conflictURLs removeAllObjects];
    }
}

#pragma mark - Private methods

- (void)_callCompletionHandlerWithError:(NSError *)error
{
    [_connection setDelegate:_originalDelegate];
    if (_completionHandler)
        _completionHandler(_connection, error);
}

- (void)_syncLocalURL:(NSURL *)local toRemotePath:(NSString *)remote
{
    ECASSERT(_syncs);
    
    NSNumber *isDirectory = nil;
    for (NSURL *localFileURL in [[NSFileManager defaultManager] enumeratorAtURL:local includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLFileSizeKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil])
    {
        [_syncs setObject:localFileURL forKey:[remote stringByAppendingPathComponent:[localFileURL lastPathComponent]]];
        [localFileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if ([isDirectory boolValue])
        {
            [self _syncLocalURL:localFileURL toRemotePath:[remote stringByAppendingPathComponent:[localFileURL lastPathComponent]]];
        }
    }
    
    if ( ! _syncIsFromRemote)
    {
        _transfersStarted++;
        [_connection changeToDirectory:remote];
        [_connection directoryContents];
    }
}

@end

