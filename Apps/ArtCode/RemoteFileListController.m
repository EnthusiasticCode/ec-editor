//
//  RemoteFileListController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/09/12.
//
//

#import "RemoteFileListController.h"

#import "ArtCodeRemote.h"
#import <Connection/CKConnectionRegistry.h>
#import "NSArray+ScoreForAbbreviation.h"
#import "Keychain.h"

#import "RemoteNavigationController.h"
#import "HighlightTableViewCell.h"
#import "UIImage+AppStyle.h"


@implementation RemoteFileListController {
  ArtCodeRemote *_remote;
  id<CKConnection> _connection;
  NSString *_remotePath;
  
  BOOL _keychainUsed;
  NSURLCredential *_loginCredential;
  
  NSArray *_directoryContent;
  NSArray *_filteredItems;
  NSArray *_filteredItemsHitMasks;

  NSMutableArray *_selectedItems;
}

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote connection:(id<CKConnection>)connection path:(NSString *)remotePath {
  self = [super init];
  if (!self)
    return nil;
  _remote = remote;
  _connection = connection;
  _remotePath = remotePath;
  return self;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  _directoryContent = nil;
}

- (void)loadView {
  [super loadView];
  [[NSBundle mainBundle] loadNibNamed:@"RemoteLogin" owner:self options:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.searchBar.placeholder = @"Filter files in this remote folder";
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self _connectToURL:_remote.url];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [_selectedItems removeAllObjects];
}

- (NSArray *)filteredItems {
  // In no content is present, returns nil and ask for a refresh
  if (!_directoryContent) {
    [self _listContentOfDirectoryWithFullPath:_remotePath];
    return nil;
  }
  
  // Filtering
  if ([self.searchBar.text length] != 0) {
    NSArray *hitsMask = nil;
    _filteredItems = [_directoryContent sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitsMask extrapolateTargetStringBlock:^NSString *(NSDictionary *element) {
      return [element objectForKey:cxFilenameKey];
    }];
    _filteredItemsHitMasks = hitsMask;
  }
  else
  {
    _filteredItems = _directoryContent;
    _filteredItemsHitMasks = nil;
  }
  return _filteredItems;
}

- (void)invalidateFilteredItems {
  _filteredItems = nil;
  _filteredItemsHitMasks = nil;
  [_selectedItems removeAllObjects];
}

#pragma mark - Connection delegate

- (void)connection:(id <CKPublishingConnection>)con didConnectToHost:(NSString *)host error:(NSError *)error {
  // Called before any authentication, when the socket connects
  //self.loading = NO;
  // TODO check if properly connected
}

- (void)connection:(id <CKPublishingConnection>)con didDisconnectFromHost:(NSString *)host {
  self.loading = NO;
  
  if(con == _connection)
    _connection = nil;
  
  // Show login form to let the user log back in
  self.tableView.tableHeaderView = self.loginView;
  self.loginLabel.text = [NSString stringWithFormat:@"Login required for %@:", _remote.host];
  if (_keychainUsed)
  {
    self.loginPassword.text = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_remote.scheme host:_remote.host port:_remote.portValue] account:_remote.user];
    self.loginAlwaysAskPassword.on = NO;
  }
  if (_remote.user)
  {
    self.loginUser.text = _remote.user;
    [self.loginPassword becomeFirstResponder];
  }
  else
  {
    [self.loginUser becomeFirstResponder];
  }
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveError:(NSError *)error {
  // TODO manage error
  NSLog(@"%@", [error localizedDescription]);
}

#pragma mark Connection Authentication

- (void)connection:(id <CKPublishingConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  [self setLoading:YES];
  
  // Check for keychain password
  if (!_loginCredential && !_keychainUsed && _remote.user)
  {
    NSString *password = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_remote.scheme host:_remote.host port:_remote.portValue] account:_remote.user];
    if (password)
    {
      _loginCredential = [NSURLCredential credentialWithUser:_remote.user password:password persistence:NSURLCredentialPersistenceForSession];
      _keychainUsed = YES;
    }
  }
  
  // Login with credentials created in login view
  if (_loginCredential)
  {
    [[challenge sender] useCredential:_loginCredential forAuthenticationChallenge:challenge];
    _loginCredential = nil;
    [self _connectionSuccessfull];
    return;
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

//- (void)connection:(id <CKPublishingConnection>)con didChangeToDirectory:(NSString *)dirPath error:(NSError *)error
//{
//  [con directoryContents];
//}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error {
  [self setLoading:NO];
  
  // Cache results
  _directoryContent = contents;
  [self invalidateFilteredItems];
  [self.tableView reloadData];
  
  // Enable non-editing buttons
  for (UIBarButtonItem *barItem in self.toolNormalItems)
  {
    [(UIButton *)barItem.customView setEnabled:YES];
  }
}

//- (void)connection:(id <CKPublishingConnection>)con didCreateDirectory:(NSString *)dirPath error:(NSError *)error
//{
//
//}
//
//- (void)connection:(id <CKConnection>)con didRename:(NSString *)fromPath to:(NSString *)toPath error:(NSError *)error
//{
//
//}
//
//- (void)connection:(id <CKConnection>)con didSetPermissionsForFile:(NSString *)path error:(NSError *)error
//{
//
//}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.isEditing) {
    NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
    if ([directoryItem objectForKey:NSFileType] == NSFileTypeDirectory) {
      RemoteFileListController *remoteFileListController = [[RemoteFileListController alloc] initWithArtCodeRemote:_remote connection:_connection path:[_remotePath stringByAppendingPathComponent:[directoryItem objectForKey:cxFilenameKey]]];
      [self.remoteNavigationController pushViewController:remoteFileListController animated:YES];
    } else {
      //[self _toolEditExportAction:nil];
    }
  } else {
    [_selectedItems addObject:[self.filteredItems objectAtIndex:indexPath.row]];
  }
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.isEditing) {
    [_selectedItems removeObject:[self.filteredItems objectAtIndex:indexPath.row]];
  }
  [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
}

#pragma mark - Public Methods

- (IBAction)loginAction:(id)sender {
  self.loading = YES;
  if (!self.loginAlwaysAskPassword.isOn)
  {
    [[Keychain sharedKeychain] setPassword:self.loginPassword.text forServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_remote.scheme host:_remote.host port:_remote.portValue] account:self.loginUser.text];
  }
  // Create a temporary login credential and try to connect again
  _loginCredential = [NSURLCredential credentialWithUser:self.loginUser.text password:self.loginPassword.text persistence:NSURLCredentialPersistenceForSession];
  [self _connectToURL:_remote.url];
}

#pragma mark - Private Methods

- (void)setLoading:(BOOL)loading {
  if (loading) {
    ASSERT(self.loadingView);
    [self.view addSubview:self.loadingView];
    self.loadingView.frame = self.view.bounds;
  } else {
    [self.loadingView removeFromSuperview];
  }
}

- (void)_connectToURL:(NSURL *)url {
  // If already connected, return
  if (_connection) {
    return;
  }
  
  // Start connection procedure
  [self setLoading:YES];
  self.tableView.tableHeaderView = nil;
  _keychainUsed = NO;
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  _connection = (id<CKConnection>)[[CKConnectionRegistry sharedConnectionRegistry] connectionWithRequest:request];
  [_connection setDelegate:self];
  [_connection connect];
}

/// This methos setup the connection to the underlying navigation controller and pushes the brwser controller
- (void)_connectionSuccessfull {
  ASSERT(_connection);
  [self setLoading:NO];
  self.remoteNavigationController.connection = _connection;
  [self invalidateFilteredItems];
  [self.tableView reloadData];
}

- (void)_listContentOfDirectoryWithFullPath:(NSString *)fullPath {
  [self setLoading:YES];
  
  if (![_connection isConnected]) {
    return;
  }
  
  [_connection setDelegate:self];
  [_connection changeToDirectory:fullPath.length ? fullPath : @"/"];
  [_connection directoryContents];
}

@end
