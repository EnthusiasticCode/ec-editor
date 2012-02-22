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
#import "NSArray+ScoreForAbbreviation.h"
#import "UIImage+AppStyle.h"
#import "ArtCodeTab.h"

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
    
    NSURLCredential *_loginCredential;
}
@synthesize loginLabel = _loginLabel;
@synthesize loginUser = _loginUser;
@synthesize loginPassword = _loginPassword;
@synthesize loginSavePassword = _loginSavePassword;

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
        [self _changeToDirectory:value.path];
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
    if ([self.searchBar.text length] != 0)
    {
        NSArray *hitsMask = nil;
        _filteredItems = [_directoryItems sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitsMask extrapolateTargetStringBlock:^NSString *(NSDictionary *element) {
            return [element objectForKey:cxFilenameKey];
        }];
        _filteredItemsHitMasks = hitsMask;
    }
    else
    {
        _filteredItems = _directoryItems;
        _filteredItemsHitMasks = nil;
    }
    return _filteredItems;
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
    _loginCredential = nil;
    [super viewDidDisappear:animated];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
    cell.textLabel.text = [directoryItem objectForKey:cxFilenameKey];
    cell.textLabelHighlightedCharacters = _filteredItemsHitMasks ? [_filteredItemsHitMasks objectAtIndex:indexPath.row] : nil;
    if ([directoryItem objectForKey:NSFileType] == NSFileTypeDirectory)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[[directoryItem objectForKey:cxFilenameKey] pathExtension]];
    }
    // TODO also use NSFileSize
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
    if ([directoryItem objectForKey:NSFileType] == NSFileTypeDirectory)
    {
        [self.artCodeTab pushURL:[self.URL URLByAppendingPathComponent:[directoryItem objectForKey:cxFilenameKey] isDirectory:YES]];
    }
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
    self.loading = NO;
    // TODO check for keychain password first
    
    // Login with credentials created in login view
    if (_loginCredential)
    {
        [[challenge sender] useCredential:_loginCredential forAuthenticationChallenge:challenge];
        _loginCredential = nil;
        self.tableView.tableHeaderView = nil;
        return;
    }
    
    // Cancel authentication and show login view
    self.tableView.tableHeaderView = [[[NSBundle mainBundle] loadNibNamed:@"RemoteLogin" owner:self options:nil] objectAtIndex:0];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    if (self.URL.user)
    {
        self.loginUser.text = self.URL.user;
        [self.loginPassword becomeFirstResponder];
    }
    else
    {
        [self.loginUser becomeFirstResponder];
    }
    [[challenge sender] cancelAuthenticationChallenge:challenge];
    
    
//    [[challenge sender] useCredential:[NSURLCredential credentialWithUser:@"nikso.net" password:@"aenasahg" persistence:NSURLCredentialPersistenceForSession] forAuthenticationChallenge:challenge];
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
    [con directoryContents];
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error
{
    self.loading = NO;
    _directoryItems = [contents mutableCopy];
    [self invalidateFilteredItems];
    [self.tableView reloadData];
}

- (void)connection:(id <CKConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath moreComing:(BOOL)flag
{
    [_directoryItems addObjectsFromArray:contents];
    if (!flag)
    {
        self.loading = NO;
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

#pragma mark - Login Screen

- (IBAction)loginAction:(id)sender
{
    _loginCredential = [NSURLCredential credentialWithUser:self.loginUser.text password:self.loginPassword.text persistence:NSURLCredentialPersistenceForSession];
    [self _connectToURL:self.URL];
    [self _changeToDirectory:self.URL.path];
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

- (void)viewDidUnload {
    [self setLoginLabel:nil];
    [self setLoginUser:nil];
    [self setLoginPassword:nil];
    [self setLoginSavePassword:nil];
    [super viewDidUnload];
}

@end
