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
#import <objc/runtime.h>

@interface RemoteTransferController ()

@end

@implementation RemoteTransferController {
    id<CKConnection> _connection;
    NSArray *_items;
    NSURL *_remoteURL;
    NSURL *_localURL;
    void (^_completionHandler)(id<CKConnection>);
    
    NSMutableArray *_transfers;
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
    _transfers = nil;
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

#pragma mark - Transfer Delegate

//- (void)transferDidBegin:(CKTransferRecord *)transfer
//{
//}

//- (void)transfer:(CKTransferRecord *)transfer transferredDataOfLength:(unsigned long long)length
//{
//    
//}

- (void)transfer:(CKTransferRecord *)transfer progressedTo:(NSNumber *)percent
{
    if (!self.progressView.isHidden)
    {
        static void *_transferProgressNumber;
        float totalProgress = 0;
        for (CKTransferRecord *record in _transfers)
        {
            if (record == transfer)
            {
                totalProgress += [percent floatValue];
                objc_setAssociatedObject(transfer, &_transferProgressNumber, percent, OBJC_ASSOCIATION_COPY_NONATOMIC);
            }
            else
            {
                NSNumber *number = objc_getAssociatedObject(record, &_transferProgressNumber);
                if (number)
                    totalProgress += [number floatValue];
            }
        }
        [self.progressView setProgress:(totalProgress + _transfersCompleted * 100.0) / (([_transfers count] + _transfersCompleted) * 100.0) animated:YES];
    }
}

- (void)transfer:(CKTransferRecord *)transfer receivedError:(NSError *)error
{
    [_transfers removeObject:transfer];
    if (_completionHandler && [_transfers count] == 0 && [self.conflictURLs count] == 0)
        _completionHandler(_connection);
}

- (void)transferDidFinish:(CKTransferRecord *)transfer error:(NSError *)error
{
    _transfersCompleted++;
    [_transfers removeObject:transfer];
    if (_completionHandler && [_transfers count] == 0 && [self.conflictURLs count] == 0)
        _completionHandler(_connection);
}

#pragma mark Connection Downloads

//- (void)connection:(id <CKConnection>)con download:(NSString *)path progressedTo:(NSNumber *)percent
//{
//    
//}
//
//- (void)connection:(id <CKConnection>)con download:(NSString *)path receivedDataOfLength:(unsigned long long)length
//{
//    
//}
//
//- (void)connection:(id <CKConnection>)con downloadDidBegin:(NSString *)remotePath
//{
//    
//}
//
//- (void)connection:(id <CKConnection>)con downloadDidFinish:(NSString *)remotePath error:(NSError *)error
//{
//    
//}

#pragma mark - Public methods

- (void)downloadItems:(NSArray *)items fromConnection:(id<CKConnection>)connection url:(NSURL *)remoteURL toLocalURL:(NSURL *)localURL completionHandler:(void (^)(id<CKConnection>))completionHandler
{
    ECASSERT(connection != nil);
    
    // Reset progress
    self.progressView.progress = 0;
    _transfersCompleted = 0;

    // First pass to download items that are not conflicting with local files
    _transfers = [NSMutableArray arrayWithCapacity:[items count]];
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
            // TODO make api more similar to single file one with delegate for transfer
            [_transfers addObject:[connection recursivelyDownload:[item objectForKey:cxFilenameKey] to:[localURL path] overwrite:YES]];
        }
        else
        {
            [_transfers addObject:[connection downloadFile:[item objectForKey:cxFilenameKey] toDirectory:[localURL path] overwrite:YES delegate:self]];
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
    if ([_transfers count] == 0 && [self.conflictURLs count] == 0)
    {
        completionHandler(connection);
    }
    else
    {
        _connection = connection;
        _items = items;
        _remoteURL = remoteURL;
        _localURL = localURL;
        _completionHandler = [completionHandler copy];
    }
}

#pragma mark - Actions

- (void)replaceAction:(id)sender
{
    for (NSIndexPath *indexPath in [self.conflictTableView indexPathsForSelectedRows])
    {
        NSDictionary *item = [self.conflictURLs objectAtIndex:indexPath.row];
        if ([item objectForKey:NSFileType] == NSFileTypeDirectory)
        {
            // TODO make api more similar to single file one with delegate for transfer
            [_transfers addObject:[_connection recursivelyDownload:[item objectForKey:cxFilenameKey] to:[_localURL path] overwrite:YES]];
        }
        else
        {
            [_transfers addObject:[_connection downloadFile:[item objectForKey:cxFilenameKey] toDirectory:[_localURL path] overwrite:YES delegate:self]];
        }
    }
    [self keepOriginalAction:sender];
}

- (void)keepOriginalAction:(id)sender
{
    [super keepOriginalAction:sender];
    if (_completionHandler && [_transfers count] == 0)
    {
        _completionHandler(_connection);
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

@end

