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
#import "ArtCodeProject.h"
#import "Keychain.h"
#import "DirectoryBrowserController.h"
#import "RemoteTransferController.h"

#import <Connection/CKConnectionRegistry.h>

@interface RemoteBrowserController ()

/// URLs selected in the table view
@property (nonatomic, strong, readonly) NSMutableArray *_selectedItems;

- (void)_connectToURL:(NSURL *)url;
- (void)_changeToDirectory:(NSString *)directory;
- (void)_closeConnection;

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

- (void)_modalNavigationControllerPresentWithRootViewController:(UIViewController *)viewController;
- (void)_modalNavigationControllerDismissAction:(id)sender;
- (void)_modalNavigationControllerDownloadAction:(id)sender;

@end

@implementation RemoteBrowserController {
    id<CKPublishingConnection> _connection;

    /// Array of unfiltered items in the current directory
    NSMutableArray *_directoryItems;
    NSArray *_filteredItems;
    NSArray *_filteredItemsHitMasks;
    
    NSURLCredential *_loginCredential;
    /// Indicates that a keychain password has been used for authentication. If authentication fails and _keychainUsed is YES, the login view is shown.
    BOOL _keychainUsed;
    
    UINavigationController *_modalNavigationController;
    UIActionSheet *_toolEditExportActionSheet;
}

@synthesize loginLabel = _loginLabel;
@synthesize loginUser = _loginUser;
@synthesize loginPassword = _loginPassword;
@synthesize loginAlwaysAskPassword = _loginAlwaysAskPassword;

#pragma mark - Properties

@synthesize _selectedItems;

- (NSMutableArray *)_selectedItems
{
    if (!_selectedItems)
        _selectedItems = [NSMutableArray new];
    return _selectedItems;
}

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

- (void)loadView
{
    [super loadView];
    self.toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
    
    self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
}

- (void)viewDidUnload
{
    _directoryItems = nil;
    [self setLoginLabel:nil];
    [self setLoginUser:nil];
    [self setLoginPassword:nil];
    [self setLoginAlwaysAskPassword:nil];
    _modalNavigationController = nil;
    _selectedItems = nil;
    _toolEditExportActionSheet = nil;
    [super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.URL = nil;
    _directoryItems = nil;
    _loginCredential = nil;
    [super viewDidDisappear:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [_selectedItems removeAllObjects];
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
    // Select item if neede
    if ([_selectedItems containsObject:directoryItem])
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isEditing)
    {
        NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
        if ([directoryItem objectForKey:NSFileType] == NSFileTypeDirectory)
        {
            [self.artCodeTab pushURL:[self.URL URLByAppendingPathComponent:[directoryItem objectForKey:cxFilenameKey] isDirectory:YES]];
        }
        else
        {
            [self _toolEditExportAction:nil];
        }
    }
    else
    {
        [self._selectedItems addObject:[self.filteredItems objectAtIndex:indexPath.row]];
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self._selectedItems removeObject:[self.filteredItems objectAtIndex:indexPath.row]];
    [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
}

#pragma mark - Connection delegate

- (void)connection:(id <CKPublishingConnection>)con didConnectToHost:(NSString *)host error:(NSError *)error
{
    // Called before any authentication, when the socket connects
    self.loading = NO;
}

- (void)connection:(id <CKPublishingConnection>)con didDisconnectFromHost:(NSString *)host
{
    self.loading = NO;
    
    if(con == _connection)
        _connection = nil;
    
    // Show login form to let the user log back in
    self.tableView.tableHeaderView = [[[NSBundle mainBundle] loadNibNamed:@"RemoteLogin" owner:self options:nil] objectAtIndex:0];
    self.loginLabel.text = [NSString stringWithFormat:@"Login required for %@:", self.URL.host];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    if (_keychainUsed)
    {
        self.loginPassword.text = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[NSString stringWithFormat:@"%@://%@", self.URL.scheme, self.URL.host] account:self.URL.user];
        self.loginAlwaysAskPassword.on = NO;
    }
    if (self.URL.user)
    {
        self.loginUser.text = self.URL.user;
        [self.loginPassword becomeFirstResponder];
    }
    else
    {
        [self.loginUser becomeFirstResponder];
    }
    _directoryItems = nil;
    [self invalidateFilteredItems];
    [self.tableView reloadData];
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveError:(NSError *)error
{
    NSLog(@"%@", [error localizedDescription]);
}

#pragma mark Connection Authentication

- (void)connection:(id <CKPublishingConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    self.loading = YES;
    
    // Check for keychain password
    if (!_loginCredential && !_keychainUsed && self.URL.user)
    {
        NSString *password = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[NSString stringWithFormat:@"%@://%@", self.URL.scheme, self.URL.host] account:self.URL.user];
        if (password)
        {
            _loginCredential = [NSURLCredential credentialWithUser:self.URL.user password:password persistence:NSURLCredentialPersistenceForSession];
            _keychainUsed = YES;
        }
    }
    
    // Login with credentials created in login view
    if (_loginCredential)
    {
        [[challenge sender] useCredential:_loginCredential forAuthenticationChallenge:challenge];
        _loginCredential = nil;
        self.tableView.tableHeaderView = nil;
        [self setLoginLabel:nil];
        [self setLoginUser:nil];
        [self setLoginPassword:nil];
        [self setLoginAlwaysAskPassword:nil];
        return;
    }
    
    // Disable non-editing buttons, they will be re-enabled when receiving directory content
    for (UIBarButtonItem *barItem in self.toolNormalItems)
    {
        [(UIButton *)barItem.customView setEnabled:NO];
    }
    
    // Cancel authentication (and show login view uppon disconnection)
    [[challenge sender] cancelAuthenticationChallenge:challenge];
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

//- (void)connection:(id <CKConnection>)con didDeleteDirectory:(NSString *)dirPath error:(NSError *)error
//{
//    
//}
//
//- (void)connection:(id <CKPublishingConnection>)con didDeleteFile:(NSString *)path error:(NSError *)error
//{
//    
//}

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
    // Enable non-editing buttons
    for (UIBarButtonItem *barItem in self.toolNormalItems)
    {
        [(UIButton *)barItem.customView setEnabled:YES];
    }
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
    self.loading = YES;
    if (!self.loginAlwaysAskPassword.isOn)
    {
        [[Keychain sharedKeychain] setPassword:self.loginPassword.text forServiceWithIdentifier:[NSString stringWithFormat:@"%@://%@", self.URL.scheme, self.URL.host] account:self.loginUser.text];
    }
    // Create a temporary login credential and try to connect again
    _loginCredential = [NSURLCredential credentialWithUser:self.loginUser.text password:self.loginPassword.text persistence:NSURLCredentialPersistenceForSession];
    [self _connectToURL:self.URL];
    [self _changeToDirectory:self.URL.path];
}

#pragma mark - Action Sheed Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Delete
    if (actionSheet == _toolEditDeleteActionSheet)
    {
        if (buttonIndex != actionSheet.destructiveButtonIndex)
            return;
        RemoteTransferController *transferController = [RemoteTransferController new];
        transferController.navigationItem.rightBarButtonItem = nil;
        [self _modalNavigationControllerPresentWithRootViewController:transferController];
        [transferController deleteItems:self._selectedItems fromConnection:(id<CKConnection>)_connection url:self.URL completionHandler:^(id<CKConnection> connection) {
            self.loading = YES;
            [self setEditing:NO animated:YES];
            [_connection directoryContents];
            [self dismissViewControllerAnimated:YES completion:^{
                _modalNavigationController = nil;
            }];
        }];
    }
    else if (actionSheet == _toolEditExportActionSheet)
    {
        if (buttonIndex == 0) // Download
        {
            // Show directory browser presenter to select where to download
            DirectoryBrowserController *directoryBrowser = [DirectoryBrowserController new];
            directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Download" style:UIBarButtonItemStyleDone target:self action:@selector(_modalNavigationControllerDownloadAction:)];
            directoryBrowser.URL = self.artCodeTab.currentProject.URL;
            [self _modalNavigationControllerPresentWithRootViewController:directoryBrowser];
        }
        else if (buttonIndex == 1) // Move
        {
            // TODO
        }
    }
}

#pragma mark - Private methods

- (void)_connectToURL:(NSURL *)url
{
    self.loading = YES;
    _keychainUsed = NO;
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

#pragma mark - Tool actions

- (void)_toolEditExportAction:(id)sender
{
    if (!_toolEditExportActionSheet)
    {
        _toolEditExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Download selected", @"Move selected", nil];
    }
    [_toolEditExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

#pragma mark Modal Navigation Controller for Progress

- (void)_modalNavigationControllerPresentWithRootViewController:(UIViewController *)viewController
{
    // Prepare left cancel button item
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_modalNavigationControllerDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    viewController.navigationItem.leftBarButtonItem = cancelItem;

    // Prepare new modal navigation controller and present it
    _modalNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    _modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:_modalNavigationController animated:YES completion:^{
        // In case the transfer finishes before the presentation animation, dismiss immediatly
        if ([_modalNavigationController.visibleViewController isKindOfClass:[RemoteTransferController class]] 
            && [(RemoteTransferController *)_modalNavigationController.visibleViewController isTransferFinished])
        {
            [self dismissViewControllerAnimated:YES completion:^{
                _modalNavigationController = nil;
            }];
        }
    }];
}

- (void)_modalNavigationControllerDismissAction:(id)sender
{
    if ([_modalNavigationController.visibleViewController isKindOfClass:[RemoteTransferController class]] && ![(RemoteTransferController *)_modalNavigationController.visibleViewController isTransferFinished])
    {
        [(RemoteTransferController *)_modalNavigationController.visibleViewController cancelCurrentTransfer];
    }
    else
    {
        if (self.tableView.indexPathForSelectedRow)
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            _modalNavigationController = nil;
        }];
    }
}

- (void)_modalNavigationControllerDownloadAction:(id)sender
{
    // Retrieve URL to move to
    DirectoryBrowserController *directoryBrowser = (DirectoryBrowserController *)_modalNavigationController.topViewController;
    NSURL *moveURL = directoryBrowser.selectedURL;
    if (moveURL == nil)
        moveURL = directoryBrowser.URL;
    
    // Show conflit resolution controller
    RemoteTransferController *transferController = [RemoteTransferController new];
    // TODO cancel item should also call cancel for the transferController. could be done checking if the nav controller child controller is the remotetransfer and isfinished
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    transferController.navigationItem.leftBarButtonItem = cancelItem;
    [_modalNavigationController pushViewController:transferController animated:YES];
    // Resolve conflicts and start downloading
    [transferController downloadItems:([self._selectedItems count] ? self._selectedItems : [NSArray arrayWithObject:[self.filteredItems objectAtIndex:self.tableView.indexPathForSelectedRow.row]]) fromConnection:(id<CKConnection>)_connection url:self.URL toLocalURL:moveURL completionHandler:^(id<CKConnection> connection) {
        [self setEditing:NO animated:YES];
        if (self.tableView.indexPathForSelectedRow)
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            _modalNavigationController = nil;
        }];
    }];
}

@end
