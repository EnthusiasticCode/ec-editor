//
//  RemoteBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteBrowserController.h"
#import "SingleTabController.h"
#import "HighlightTableViewCell.h"
#import <Connection/CKConnectionRegistry.h>

@interface RemoteBrowserController ()

- (void)_connectToURL:(NSURL *)url;
- (void)_changeToDirectory:(NSString *)directory;
- (void)_closeConnection;

@end

@implementation RemoteBrowserController {
    id<CKPublishingConnection> _connection;

    /// Array of unfiltered items in the current directory
    NSMutableArray *_directoryItems;
    NSArray *_filteredItems;
    NSArray *_filteredItemsHitMasks;
}

#pragma mark - Properties

@synthesize URL;

- (void)setURL:(NSURL *)value
{
    if (value == URL)
        return;
    [self willChangeValueForKey:@"URL"];
    if (_connection && [value.host isEqualToString:URL.host])
    {
        // If already connected to the host, just change directory
        [self _changeToDirectory:value.path];
    }
    else if (value != nil)
    {
        [self _connectToURL:value];
    }
    else
    {
        [self _closeConnection];
    }
    URL = value;
    [self didChangeValueForKey:@"URL"];
}

- (NSArray *)filteredItems
{
    // TODO filter
    return _directoryItems;
}

- (void)invalidateFilteredItems
{
    _filteredItems = nil;
    _filteredItemsHitMasks = nil;
}

#pragma mark - View lifecycle

- (void)viewDidDisappear:(BOOL)animated
{
    self.URL = nil;
    _directoryItems = nil;
    [super viewDidDisappear:animated];
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
    cell.textLabel.text = [directoryItem objectForKey:cxFilenameKey];
    // TODO also use NSFileSize, NSFileType and parse file extension
    
    return cell;
}

#pragma mark - Connection delegate

- (void)connection:(id <CKPublishingConnection>)con didConnectToHost:(NSString *)host error:(NSError *)error
{
    // Called before any authentication, when the socket connects
    self.loading = NO;
}

- (void)connection:(id <CKPublishingConnection>)con didDisconnectFromHost:(NSString *)host
{
    if(con == _connection)
        _connection = nil;
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveError:(NSError *)error
{
    NSLog(@"%@", [error localizedDescription]);
}

#pragma mark Connection Authentication

- (void)connection:(id <CKPublishingConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[challenge sender] useCredential:[NSURLCredential credentialWithUser:@"nikso.net" password:@"aenasahg" persistence:NSURLCredentialPersistenceForSession] forAuthenticationChallenge:challenge];
}

- (void)connection:(id <CKPublishingConnection>)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    
}

- (NSString *)connection:(id <CKConnection>)con passphraseForHost:(NSString *)host username:(NSString *)username publicKeyPath:(NSString *)publicKeyPath
{
    // For SFTP passphrase support
    return nil;
}

#pragma mark Connection Directory Management

- (void)connection:(id <CKPublishingConnection>)con didCreateDirectory:(NSString *)dirPath error:(NSError *)error
{
    
}

- (void)connection:(id <CKConnection>)con didDeleteDirectory:(NSString *)dirPath error:(NSError *)error
{
    
}

- (void)connection:(id <CKPublishingConnection>)con didDeleteFile:(NSString *)path error:(NSError *)error
{
    
}

#pragma mark Connection Editing Content

- (void)connection:(id <CKPublishingConnection>)con didChangeToDirectory:(NSString *)dirPath error:(NSError *)error
{
    NSLog(@"changed to directory: %@", dirPath);
    [_connection directoryContents];
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error
{
    // TODO understand why it is called 3 times at start
    _directoryItems = [contents mutableCopy];
    [self invalidateFilteredItems];
    [self.tableView reloadData];
}

- (void)connection:(id <CKConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath moreComing:(BOOL)flag
{
    [_directoryItems addObjectsFromArray:contents];
    if (!flag)
    {
        [self invalidateFilteredItems];
        [self.tableView reloadData];
    }
}

- (void)connection:(id <CKConnection>)con didRename:(NSString *)fromPath to:(NSString *)toPath error:(NSError *)error
{
    
}

- (void)connection:(id <CKConnection>)con didSetPermissionsForFile:(NSString *)path error:(NSError *)error
{

}

#pragma mark Connection Downloads

- (void)connection:(id <CKConnection>)con download:(NSString *)path progressedTo:(NSNumber *)percent
{
    
}

- (void)connection:(id <CKConnection>)con download:(NSString *)path receivedDataOfLength:(unsigned long long)length
{
    
}

- (void)connection:(id <CKConnection>)con downloadDidBegin:(NSString *)remotePath
{
    
}

- (void)connection:(id <CKConnection>)con downloadDidFinish:(NSString *)remotePath error:(NSError *)error
{
    
}

#pragma mark Connection Uploads

- (void)connection:(id <CKConnection>)con upload:(NSString *)remotePath progressedTo:(NSNumber *)percent
{
    
}

- (void)connection:(id <CKConnection>)con upload:(NSString *)remotePath sentDataOfLength:(unsigned long long)length
{
    
}

- (void)connection:(id <CKPublishingConnection>)con uploadDidBegin:(NSString *)remotePath
{
    
}

- (void)connection:(id <CKPublishingConnection>)con uploadDidFinish:(NSString *)remotePath error:(NSError *)error
{
    
}

- (void)connection:(id <CKConnection>)con didCancelTransfer:(NSString *)remotePath
{
    
}

- (void)connection:(id <CKConnection>)con checkedExistenceOfPath:(NSString *)path pathExists:(BOOL)exists error:(NSError *)error
{
    
}

#pragma mark Connection Transcript

- (void)connection:(id<CKPublishingConnection>)connection appendString:(NSString *)string toTranscript:(CKTranscriptType)transcript
{
    NSLog(@"transcript: %@", string);
}

#pragma mark - Private methods

- (void)_connectToURL:(NSURL *)url
{
    self.loading = YES;
    [self _closeConnection];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    _connection = [[CKConnectionRegistry sharedConnectionRegistry] connectionWithRequest:request];
    [_connection setDelegate:self];
    [_connection connect]; 
}

- (void)_changeToDirectory:(NSString *)directory
{
    self.loading = YES;
    if (!_directoryItems)
        _directoryItems = [NSMutableArray new];
    else
        [_directoryItems removeAllObjects];
    [_connection changeToDirectory:[directory length] ? directory : @"/"];
}

- (void)_closeConnection
{
    [_connection setDelegate:nil];
    [_connection disconnect];
}

@end
