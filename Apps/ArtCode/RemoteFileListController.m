//
//  RemoteFileListController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/09/12.
//
//

#import "RemoteFileListController.h"

#import "ArtCodeRemote.h"
#import "ReactiveConnection.h"
#import <Connection/CKConnectionRegistry.h>
#import "NSArray+ScoreForAbbreviation.h"
#import "Keychain.h"

#import "RemoteNavigationController.h"
#import "HighlightTableViewCell.h"
#import "UIImage+AppStyle.h"

@interface RemoteFileListController ()
@property (nonatomic, strong) ReactiveConnection *connection;
@property (nonatomic, strong) NSURLCredential *authenticationCredentials;
@property (nonatomic, strong) NSString *remotePath;
@property (nonatomic, strong) NSArray *directoryContent;
@property (nonatomic) BOOL showLogin;
@property (nonatomic) BOOL showLoading;
@end


@implementation RemoteFileListController {
  ArtCodeRemote *_remote;
  
  BOOL _keychianAttemptUsed;
  NSURLAuthenticationChallenge *_authenticationChallenge;
  
  NSArray *_filteredItems;
  NSArray *_filteredItemsHitMasks;

  NSMutableArray *_selectedItems;
}

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote connection:(ReactiveConnection *)connection path:(NSString *)remotePath {
  self = [super init];
  if (!self)
    return nil;
  ASSERT(remote && connection);
  _remote = remote;
  _connection = connection;
  self.remotePath = remotePath ?: @"/";
  
  // RAC
  __weak RemoteFileListController *this = self;
  
  // Directory content update reaction
  RAC(self.directoryContent) = [[[self.connection directoryContentsForPath:self.remotePath]
                                 where:^BOOL(RACTuple *pathAndContent) {
                                   return [this.remotePath isEqualToString:pathAndContent.first];
                                 }]
                                select:^id(RACTuple *pathAndContent) {
                                  return pathAndContent.second;
                                }];
  
  [RACAble(self.directoryContent) subscribeNext:^(id x) {
    [this invalidateFilteredItems];
  }];
  
  // Connected refresh reaction
  [[RACAble(self.connection.connected) where:^BOOL(id x) {
    return [x boolValue];
  }] subscribeNext:^(id x) {
    [this.connection directoryContentsForPath:this.remotePath];
  }];
  
  // Login reaction
  [RACAble(self.authenticationCredentials) subscribeNext:^(NSURLCredential *credentials) {
    this.showLoading = YES;
    [[this.connection connectWithCredentials:credentials] subscribeNext:^(id x) {
      this.showLoading = NO;
      this.showLogin = ![x boolValue];
    }];
  }];
  
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
  
  // Connect immediatly if we have a stored keychain password for the remote
  if (!self.connection.isConnected) {
    NSString *password;
    if (_remote.scheme && _remote.host && (password = [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_remote.scheme host:_remote.host port:_remote.portValue] account:_remote.user])) {
      self.authenticationCredentials = [NSURLCredential credentialWithUser:_remote.user password:password persistence:NSURLCredentialPersistenceForSession];
    } else {
      self.showLogin = YES;
    }
  }
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
  if (!self.loginAlwaysAskPassword.isOn) {
    [[Keychain sharedKeychain] setPassword:self.loginPassword.text forServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_remote.scheme host:_remote.host port:_remote.portValue] account:self.loginUser.text];
  }
  // Create a temporary login credential and try to connect again
  self.authenticationCredentials = [NSURLCredential credentialWithUser:self.loginUser.text password:self.loginPassword.text persistence:NSURLCredentialPersistenceForSession];
}

#pragma mark - Private Methods

- (void)setShowLogin:(BOOL)showLogin {
  if (_showLogin == showLogin) {
    return;
  }
  
  _showLogin = showLogin;
  
  if (showLogin) {
    ASSERT(self.loginView);
    [self.view addSubview:self.loginView];
    self.loginView.frame = self.view.bounds;
    self.loginLabel.text = [NSString stringWithFormat:@"Login required for %@:", _remote.host];
    if (_remote.user) {
      self.loginUser.text = _remote.user;
      [self.loginPassword becomeFirstResponder];
    } else {
      [self.loginUser becomeFirstResponder];
    }
  } else {
    [self.loginView removeFromSuperview];
  }
}

- (void)setShowLoading:(BOOL)loading {
  if (_showLoading == loading) {
    return;
  }
  
  _showLoading = loading;
  
  if (loading) {
    ASSERT(self.loadingView);
    [self.view addSubview:self.loadingView];
    self.loadingView.frame = self.view.bounds;
  } else {
    [self.loadingView removeFromSuperview];
  }
}

@end
