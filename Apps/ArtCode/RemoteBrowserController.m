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

#import "Keychain.h"
#import "FolderBrowserController.h"
#import "RemoteTransferController.h"

#import "ArtCodeURL.h"
#import "ACProject.h"

#import <Connection/CKConnectionRegistry.h>

@interface RemoteBrowserController ()

/// URLs selected in the table view
@property (nonatomic, strong, readonly) NSMutableArray *_selectedItems;

- (void)_connectToURL:(NSURL *)url;
- (void)_changeToDirectory:(NSString *)directory;
- (void)_closeConnection;

- (void)_toolEditExportAction:(id)sender;

- (void)_modalNavigationControllerDownloadAction:(id)sender;
- (void)_modalNavigationControllerSyncAction:(id)sender;

@end

@implementation RemoteBrowserController {
  /// Array of unfiltered items in the current directory
  NSArray *_directoryItems;
  NSArray *_filteredItems;
  NSArray *_filteredItemsHitMasks;
  
  /// Caches path to array of directory contents.
  NSMutableDictionary *_directoryContentCache;
  
  NSURLCredential *_loginCredential;
  /// Indicates that a keychain password has been used for authentication. If authentication fails and _keychainUsed is YES, the login view is shown.
  BOOL _keychainUsed;
}

@synthesize loginLabel = _loginLabel;
@synthesize loginUser = _loginUser;
@synthesize loginPassword = _loginPassword;
@synthesize loginAlwaysAskPassword = _loginAlwaysAskPassword;

static void init(RemoteBrowserController *self) {
  // RAC
  __weak RemoteBrowserController *this = self;
  
  [[[RACAbleSelf(self.artCodeTab.currentURL) distinctUntilChanged] where:^BOOL(id x) {
    return this.artCodeTab.currentItem.type == ACPRemote;
  }] subscribeNext:^(NSURL *currentURL) {
    this.remote = (ArtCodeRemote *)this.artCodeTab.currentItem;
    this.remoteURL = [this.remote.URL URLByAppendingPathComponent:currentURL.path];
  }];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  init(self);
  return self;
}

- (id)initWithConnection:(id<CKConnection>)con remoteURL:(NSURL *)conUrl
{
  self = [self initWithTitle:nil searchBarStaticOnTop:NO];
  if (!self)
    return nil;
  _connection = con;
  _remoteURL = conUrl;
  init(self);
  return self;
}

#pragma mark - Properties

@synthesize connection = _connection;
@synthesize _selectedItems;

- (NSMutableArray *)_selectedItems
{
  if (!_selectedItems)
    _selectedItems = [NSMutableArray new];
  return _selectedItems;
}

@synthesize remote = _remote;
@synthesize remoteURL = _remoteURL;

- (void)setRemoteURL:(NSURL *)value
{
  if (value == _remoteURL)
    return;
  
  if (_connection && [value.host isEqualToString:_remoteURL.host])
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
  _remoteURL = value;
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
  
  // Load the bottom toolbar
  if ([self isMemberOfClass:[RemoteBrowserController class]])
    [[NSBundle mainBundle] loadNibNamed:@"RemoteBrowserBottomToolBar" owner:self options:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.searchBar.placeholder = @"Filter files in this remote folder";
  
  self.toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshAction:)]];
  
  self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
}

- (void)viewDidUnload
{
  _directoryItems = nil;
  [self setLoginLabel:nil];
  [self setLoginUser:nil];
  [self setLoginPassword:nil];
  [self setLoginAlwaysAskPassword:nil];
  _selectedItems = nil;

  [super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated
{
  self.remoteURL = nil;
  _directoryItems = nil;
  _loginCredential = nil;
  [super viewDidDisappear:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [_selectedItems removeAllObjects];
}

#pragma mark - SingleTabController

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar {
  return NO;
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
  // Select item to maintain selection on filtering
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
      [self.artCodeTab pushURL:[self.artCodeTab.currentURL URLByAppendingPathComponent:[directoryItem objectForKey:cxFilenameKey] isDirectory:YES]];
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
  if (self.isEditing)
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
  self.loginLabel.text = [NSString stringWithFormat:@"Login required for %@:", self.remoteURL.host];
  [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
  if (_keychainUsed)
  {
    self.loginPassword.text = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:self.remoteURL.scheme host:self.remoteURL.host port:[self.remoteURL.port integerValue]] account:self.remoteURL.user];
    self.loginAlwaysAskPassword.on = NO;
  }
  if (self.remoteURL.user)
  {
    self.loginUser.text = self.remoteURL.user;
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
  if (!_loginCredential && !_keychainUsed && self.remoteURL.user)
  {
    NSString *password = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:self.remoteURL.scheme host:self.remoteURL.host port:[self.remoteURL.port integerValue]] account:self.remoteURL.user];
    if (password)
    {
      _loginCredential = [NSURLCredential credentialWithUser:self.remoteURL.user password:password persistence:NSURLCredentialPersistenceForSession];
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
    // Set directory
    [self _changeToDirectory:self.remoteURL.path];
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

//- (void)connection:(id <CKPublishingConnection>)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
//{
//}

- (NSString *)connection:(id <CKConnection>)con passphraseForHost:(NSString *)host username:(NSString *)username publicKeyPath:(NSString *)publicKeyPath
{
  // For SFTP passphrase support
  return nil;
}

#pragma mark Connection Directory Management

//- (void)connection:(id <CKPublishingConnection>)con didCreateDirectory:(NSString *)dirPath error:(NSError *)error
//{
//    
//}

#pragma mark Connection Editing Content

- (void)connection:(id <CKPublishingConnection>)con didChangeToDirectory:(NSString *)dirPath error:(NSError *)error
{
  // TODO check cache first but keep an eye that remotetransferscontroller also uses this
  if ((_directoryItems = [_directoryContentCache objectForKey:dirPath]))
  {
    self.loading = NO;
    [self invalidateFilteredItems];
    [self.tableView reloadData];
    // Enable non-editing buttons
    for (UIBarButtonItem *barItem in self.toolNormalItems)
    {
      [(UIButton *)barItem.customView setEnabled:YES];
    }
    return;
  }
  [con directoryContents];
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error
{
  // Cache results
  if (!_directoryContentCache)
    _directoryContentCache = [NSMutableDictionary new];
  [_directoryContentCache setObject:contents forKey:dirPath];
  
  self.loading = NO;
  _directoryItems = contents;
  [self invalidateFilteredItems];
  [self.tableView reloadData];
  
  // Enable non-editing buttons
  for (UIBarButtonItem *barItem in self.toolNormalItems)
  {
    [(UIButton *)barItem.customView setEnabled:YES];
  }
}

//- (void)connection:(id <CKConnection>)con didRename:(NSString *)fromPath to:(NSString *)toPath error:(NSError *)error
//{
//    
//}
//
//- (void)connection:(id <CKConnection>)con didSetPermissionsForFile:(NSString *)path error:(NSError *)error
//{
//
//}

#pragma mark Connection Transcript

//- (void)connection:(id<CKPublishingConnection>)connection appendString:(NSString *)string toTranscript:(CKTranscriptType)transcript
//{
//    NSLog(@"transcript: %@", string);
//}

#pragma mark - Login Screen

- (IBAction)loginAction:(id)sender
{
  self.loading = YES;
  if (!self.loginAlwaysAskPassword.isOn)
  {
    [[Keychain sharedKeychain] setPassword:self.loginPassword.text forServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:self.remoteURL.scheme host:self.remoteURL.host port:[self.remoteURL.port integerValue]] account:self.loginUser.text];
  }
  // Create a temporary login credential and try to connect again
  _loginCredential = [NSURLCredential credentialWithUser:self.loginUser.text password:self.loginPassword.text persistence:NSURLCredentialPersistenceForSession];
  [self _connectToURL:self.remoteURL];
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
    [self modalNavigationControllerPresentViewController:transferController];
    [transferController deleteConnectionItems:self._selectedItems fromConnection:(id<CKConnection>)_connection path:self.remoteURL.path completion:^(id<CKConnection> connection, NSError *error) {
      self.loading = YES;
      [self setEditing:NO animated:YES];
      [_connection directoryContents];
      [self dismissViewControllerAnimated:YES completion:^{
        _modalNavigationController = nil;
      }];
    }];
  }
}

#pragma mark - Private methods

- (void)_connectToURL:(NSURL *)url
{
  ASSERT(!_connection && "This should only be called once.");
  self.loading = YES;
  _keychainUsed = NO;
  [self _closeConnection];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  _connection = (id<CKConnection>)[[CKConnectionRegistry sharedConnectionRegistry] connectionWithRequest:request];
  [_connection setDelegate:self];
  [_connection connect]; 
}

- (void)_changeToDirectory:(NSString *)directory
{
  if (![_connection isConnected])
    return;
  self.loading = YES;
  [_connection setDelegate:self];
  [_connection changeToDirectory:[directory length] ? directory : @"/"];
}

- (void)_closeConnection
{
  [_connection setDelegate:nil];
  [_connection disconnect];
}

#pragma mark - Tool actions

- (void)refreshAction:(id)sender
{
  self.loading = YES;
  [_connection directoryContents];
}

- (IBAction)syncAction:(id)sender
{
  FolderBrowserController *directoryBrowser = [FolderBrowserController new];
  directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStyleDone target:self action:@selector(_modalNavigationControllerSyncAction:)];
  directoryBrowser.currentFolder = self.artCodeTab.currentProject.contentsFolder;
  [self modalNavigationControllerPresentViewController:directoryBrowser];
  
}

- (void)_toolEditExportAction:(id)sender
{
  // Show directory browser presenter to select where to download
  FolderBrowserController *directoryBrowser = [FolderBrowserController new];
  directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Download" style:UIBarButtonItemStyleDone target:self action:@selector(_modalNavigationControllerDownloadAction:)];
  directoryBrowser.currentFolder = self.artCodeTab.currentProject.contentsFolder;
  [self modalNavigationControllerPresentViewController:directoryBrowser];
}

#pragma mark Modal Navigation Controller for Progress

- (void)modalNavigationControllerPresentViewController:(UIViewController *)viewController
{
  [super modalNavigationControllerPresentViewController:viewController completion:^{
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

- (void)modalNavigationControllerDismissAction:(id)sender
{
  if ([_modalNavigationController.visibleViewController isKindOfClass:[RemoteTransferController class]] && ![(RemoteTransferController *)_modalNavigationController.visibleViewController isTransferFinished])
  {
    [(RemoteTransferController *)_modalNavigationController.visibleViewController cancelCurrentTransfer];
  }
  else
  {
    if (!self.isEditing && self.tableView.indexPathForSelectedRow)
      [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [super modalNavigationControllerDismissAction:sender];
  }
}

- (void)_modalNavigationControllerDownloadAction:(id)sender
{
  // Retrieve URL to move to
  FolderBrowserController *directoryBrowser = (FolderBrowserController *)_modalNavigationController.topViewController;
  ACProjectFolder *moveFolder = directoryBrowser.selectedFolder;
  
  // Show conflit resolution controller
  RemoteTransferController *transferController = [RemoteTransferController new];
  UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(modalNavigationControllerDismissAction:)];
  [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  transferController.navigationItem.leftBarButtonItem = cancelItem;
  [_modalNavigationController pushViewController:transferController animated:YES];
  
  // Start download modal
  [transferController downloadConnectionItems:([self._selectedItems count] ? [self._selectedItems copy] : [NSArray arrayWithObject:[self.filteredItems objectAtIndex:self.tableView.indexPathForSelectedRow.row]]) fromConnection:(id<CKConnection>)_connection path:self.remoteURL.path toProjectFolder:moveFolder completion:^(id<CKConnection> connection, NSError *error) {
    [self setEditing:NO animated:YES];
    if (self.tableView.indexPathForSelectedRow)
      [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self modalNavigationControllerDismissAction:sender];
  }];
}

- (void)_modalNavigationControllerSyncAction:(id)sender
{
  // Retrieve URL to sync to
  FolderBrowserController *directoryBrowser = (FolderBrowserController *)_modalNavigationController.topViewController;
  ACProjectFolder *localFolder = directoryBrowser.selectedFolder;
  
  // Show sync controller
  RemoteTransferController *transferController = [RemoteTransferController new];
  UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(modalNavigationControllerDismissAction:)];
  [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  transferController.navigationItem.leftBarButtonItem = cancelItem;
  [_modalNavigationController pushViewController:transferController animated:YES];
  
  // Start sync
  [transferController synchronizeLocalProjectFolder:localFolder withConnection:(id<CKConnection>)_connection path:self.remoteURL.path options:nil completion:^(id<CKConnection> connection, NSError *error) {
    [self modalNavigationControllerDismissAction:sender];
  }];
}

@end
