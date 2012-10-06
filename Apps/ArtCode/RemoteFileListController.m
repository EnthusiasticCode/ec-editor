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
  
  BOOL _keychianAttemptUsed;
  NSURLAuthenticationChallenge *_authenticationChallenge;
  
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

- (void)viewWillDisappear:(BOOL)animated {
  if (_authenticationChallenge) {
    [[_authenticationChallenge sender] cancelAuthenticationChallenge:_authenticationChallenge];
    _authenticationChallenge = nil;
    _connection = nil;
  }
  [super viewWillDisappear:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [_selectedItems removeAllObjects];
}

- (NSArray *)filteredItems {
  if (!_directoryContent) {
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
  [self willChangeValueForKey:@"filteredItems"];
  _filteredItems = nil;
  _filteredItemsHitMasks = nil;
  [self didChangeValueForKey:@"filteredItems"];
}

#pragma mark - Connection delegate

- (void)connection:(id <CKPublishingConnection>)con didConnectToHost:(NSString *)host error:(NSError *)error {
  [self _connectionSuccessfull];
}

- (void)connection:(id <CKPublishingConnection>)con didDisconnectFromHost:(NSString *)host {
  self.loading = NO;
  
  if(con == _connection) {
    _connection = nil;
    _keychianAttemptUsed = NO;
  }
  
  // TODO!!! send disconnect message
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveError:(NSError *)error {
  // TODO manage error
  NSLog(@"%@", [error localizedDescription]);
}

#pragma mark Connection Authentication

- (void)connection:(id <CKPublishingConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  [self setLoading:YES];
  
  // Check if we can login out of keychain informations
  if (!_keychianAttemptUsed) {
    _keychianAttemptUsed = YES;
    NSString *password = nil;
    if (_remote.scheme && _remote.host && (password = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_remote.scheme host:_remote.host port:_remote.portValue] account:_remote.user])) {
      // TODO also come here if there is no user/password
      NSURLCredential *loginCredential = [NSURLCredential credentialWithUser:_remote.user password:password persistence:NSURLCredentialPersistenceForSession];
      [[challenge sender] useCredential:loginCredential forAuthenticationChallenge:challenge];
      return;
    }
  }
  
  // Set the authentication challenge to respond to
  _authenticationChallenge = challenge;
  
  // Show login form to let the user log back in
  [self.view addSubview:self.loginView];
  self.loginView.frame = self.view.bounds;
  self.loginLabel.text = [NSString stringWithFormat:@"Login required for %@:", _remote.host];
  if (_remote.user) {
    self.loginUser.text = _remote.user;
    [self.loginPassword becomeFirstResponder];
  } else {
    [self.loginUser becomeFirstResponder];
  }
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

- (void)connection:(id <CKPublishingConnection>)con didChangeToDirectory:(NSString *)dirPath error:(NSError *)error {
  [con directoryContents];
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error {
  [self setLoading:NO];
  
  // Cache results
  _directoryContent = contents;
  [self invalidateFilteredItems];
  
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

#pragma mark Connection Transcript

- (void)connection:(id<CKPublishingConnection>)connection appendString:(NSString *)string toTranscript:(CKTranscriptType)transcript {
  NSLog(@"transcript: %@", string);
}

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
  NSURLCredential *loginCredential = [NSURLCredential credentialWithUser:self.loginUser.text password:self.loginPassword.text persistence:NSURLCredentialPersistenceForSession];
  [[_authenticationChallenge sender] useCredential:loginCredential forAuthenticationChallenge:_authenticationChallenge];
  _authenticationChallenge = nil;
  // Refresh UI
  [self.loginView removeFromSuperview];
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
  _keychianAttemptUsed = NO;
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
  [self _listContentOfDirectoryWithFullPath:_remotePath];
}

- (void)_listContentOfDirectoryWithFullPath:(NSString *)fullPath {
  [self setLoading:YES];
  
  if (!_connection) {
    return;
  }
  
  [_connection setDelegate:self];
  [_connection changeToDirectory:fullPath.length ? fullPath : @"/"];
}

@end
