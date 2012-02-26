//
//  RemoteTransferController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteTransferController.h"
#import "UIImage+AppStyle.h"
#import <Connection/CKConnectionRegistry.h>

@interface RemoteTransferController ()

- (void)_callCompletionHandler;

@end

@implementation RemoteTransferController {
    id<CKConnection> _connection;
    NSArray *_items;
    NSURL *_remoteURL;
    NSURL *_localURL;
    void (^_completionHandler)(id<CKConnection>);
    __weak NSObject *_originalDelegate;
    
    NSMutableDictionary *_transfersProgress;
    NSUInteger _transfersStarted;
    NSInteger _transfersCompleted;
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    _connection = nil;
    _items = nil;
    _remoteURL = nil;
    _localURL = nil;
    _completionHandler = nil;
    _transfersProgress = nil;
    [super viewDidUnload];
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // TODO set icon
    cell.textLabel.text = [[self.conflictURLs objectAtIndex:indexPath.row] objectForKey:cxFilenameKey];
    
    return cell;
}


#pragma mark Connection Downloads

- (void)connection:(id <CKConnection>)con download:(NSString *)path progressedTo:(NSNumber *)percent
{
    [_transfersProgress setObject:percent forKey:path];
    if (!self.progressView.isHidden)
    {
        __block float totalProgress = 0;
        [_transfersProgress enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *progress, BOOL *stop) {
            totalProgress += [progress floatValue];
        }];
        [self.progressView setProgress:(totalProgress + _transfersCompleted * 100.0) / (([_transfersProgress count] + _transfersCompleted) * 100.0) animated:YES];
    }
}

//- (void)connection:(id <CKConnection>)con download:(NSString *)path receivedDataOfLength:(unsigned long long)length
//{
//    
//}

- (void)connection:(id <CKConnection>)con downloadDidBegin:(NSString *)remotePath
{
    _transfersStarted++;
    [_transfersProgress setObject:[NSNumber numberWithFloat:0] forKey:remotePath];
}

- (void)connection:(id <CKConnection>)con downloadDidFinish:(NSString *)remotePath error:(NSError *)error
{
    // TODO manage error
    _transfersCompleted++;
    [_transfersProgress removeObjectForKey:remotePath];
    if ([self isTransferFinished])
    {
        [self _callCompletionHandler];
    }
}

- (void)connection:(id <CKConnection>)con didCancelTransfer:(NSString *)remotePath
{
    [self connection:con downloadDidFinish:remotePath error:NULL];
}

#pragma mark - Public methods

- (void)downloadItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL toLocalURL:(NSURL *)localURL completionHandler:(void (^)(id<CKConnection>))completionHandler
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
            [connection recursivelyDownload:[item objectForKey:cxFilenameKey] to:[localURL path] overwrite:YES];
        }
        else
        {
            [connection downloadFile:[item objectForKey:cxFilenameKey] toDirectory:[localURL path] overwrite:YES delegate:nil];
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
    if ([_items count] == 0 && [self.conflictURLs count] == 0)
    {
        [connection setDelegate:_originalDelegate];
        completionHandler(connection);
    }
    else
    {
        _items = items;
        _connection = connection;
        _remoteURL = remoteURL;
        _localURL = localURL;
        _completionHandler = [completionHandler copy];
    }
}

- (BOOL)isTransferFinished
{
    return _transfersCompleted >= _transfersStarted && [_transfersProgress count] == 0 && [self.conflictURLs count] == 0;
}

- (void)cancelCurrentTransfer
{
    [_connection cancelAll];
    if (_transfersCompleted >= _transfersStarted && [_transfersProgress count] == 0)
        [self _callCompletionHandler];
}

#pragma mark - Actions

- (void)replaceAction:(id)sender
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
    [self keepOriginalAction:sender];
}

- (void)keepOriginalAction:(id)sender
{
    [super keepOriginalAction:sender];
    if ([self isTransferFinished])
    {
        [self _callCompletionHandler];
    }
    else
    {
        // Reveal progress bar if there are still transfers to be completed
        self.conflictTableView.hidden = YES;
        self.toolbar.hidden = YES;
        self.progressView.hidden = NO;
        self.navigationItem.title = @"Downloading";
    }
}

#pragma mark - Private methods

- (void)_callCompletionHandler
{
    [_connection setDelegate:_originalDelegate];
    if (_completionHandler)
        _completionHandler(_connection);
}

@end

