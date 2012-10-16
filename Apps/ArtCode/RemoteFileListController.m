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
#import "ProgressTableViewCell.h"
#import "UIImage+AppStyle.h"

static NSString * const progressSubscribableKey = @"progressSibscribable";

@interface RemoteFileListController ()
@property (nonatomic, strong) ReactiveConnection *connection;
@property (nonatomic, strong) NSURLCredential *authenticationCredentials;
@property (nonatomic, strong) NSString *remotePath;
@property (nonatomic, strong) NSArray *directoryContent;
@property (nonatomic) BOOL showLogin;
@property (nonatomic) BOOL showLoading;
@property (nonatomic, readwrite, copy) NSArray *selectedItems;
/// An array of NSDictionaries with keys: cxFilenameKey, progressSubscribableKey
@property (nonatomic, strong) NSArray *progressItems;
@end


@implementation RemoteFileListController {
  ArtCodeRemote *_remote;
  
  BOOL _keychianAttemptUsed;
  NSURLAuthenticationChallenge *_authenticationChallenge;
  
  NSArray *_filteredItems;
  NSArray *_filteredItemsHitMasks;

  NSMutableArray *_selectedItems;
  NSMutableArray *_progressItems;
}


- (void)prepareWithConnection:(ReactiveConnection *)connection artCodeRemote:(ArtCodeRemote *)remote path:(NSString *)remotePath {
  ASSERT(!_connection); // This prepare can happen only once
  ASSERT(remote && connection); // Connection and remote need to be specified
  _remote = remote;
  _connection = connection;
  self.remotePath = remotePath ?: @"/";
  
  // Preparing view
  [[NSBundle mainBundle] loadNibNamed:@"RemoteLogin" owner:self options:nil];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
  
  // RAC
  __weak RemoteFileListController *this = self;
  
  // Directory content update reaction
  RAC(self.directoryContent) = [[[self.connection directoryContents]
                                 where:^BOOL(RACTuple *pathAndContent) {
                                   return [this.remotePath isEqualToString:pathAndContent.first];
                                 }]
                                select:^id(RACTuple *pathAndContent) {
                                  return pathAndContent.second;
                                }];
  
  [[self rac_whenAny:@[RAC_KEYPATH_SELF(directoryContent), RAC_KEYPATH_SELF(progressItems)] reduce:^id(RACTuple *xs) {
    return xs;
  }] subscribeNext:^(id x) {
    [this invalidateFilteredItems];
  }];
  
  // Connected refresh reaction
  [RACAble(self.connection.connected) subscribeNext:^(id x) {
    if ([x boolValue]) {
      [this.connection changeToDirectory:this.remotePath];
    } else {
      this.showLogin = YES;
    }
  }];
  
  // Connection status reaction
  [self.connection.connectionStatus subscribeNext:^(id x) {
    enum ReactiveConnectionStatus status = [x intValue];
    if (!self.showLogin) {
      self.showLoading = status == ReactiveConnectionStatusLoading;
    }
  }];
  
  // Login reaction
  [[[RACAble(self.authenticationCredentials)
   select:^id(NSURLCredential *credentials) {
     this.showLoading = YES;
     return [this.connection connectWithCredentials:credentials];
   }] switch] subscribeNext:^(id x) {
     this.showLoading = NO;
     this.showLogin = ![x boolValue];
   }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  _directoryContent = nil;
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
  } else {
    [self.connection changeToDirectory:self.remotePath];
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [self willChangeValueForKey:@"selectedItems"];
  if (editing) {
    _selectedItems = [[NSMutableArray alloc] init];
  } else {
    _selectedItems = nil;
  }
  [self didChangeValueForKey:@"selectedItems"];
}

- (NSArray *)filteredItems {
  if (!_directoryContent && self.progressItems.count == 0) {
    return nil;
  }
  
  NSArray *contentsArray = [(_directoryContent ?: [[NSArray alloc] init]) arrayByAddingObjectsFromArray:self.progressItems];
  
  // Filtering
  if ([self.searchBar.text length] != 0) {
    NSArray *hitsMask = nil;
    _filteredItems = [contentsArray sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitsMask extrapolateTargetStringBlock:^NSString *(NSDictionary *element) {
      return [element objectForKey:cxFilenameKey];
    }];
    _filteredItemsHitMasks = hitsMask;
  }
  else
  {
    if (self.progressItems.count == 0) {
      _filteredItems = _directoryContent;
    } else {
      _filteredItems = [contentsArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2){
        // Both elements are in any case NSDictionaries with a cxFilenameKey
        return [(NSString *)[obj1 objectForKey:cxFilenameKey] compare:(NSString *)[obj2 objectForKey:cxFilenameKey]];
      }];
    }
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

#pragma mark - Public methods

- (void)addProgressItemWithURL:(NSURL *)url progressSubscribable:(RACSubscribable *)progressSubscribable {
  [self willChangeValueForKey:@"progressItems"];
  if (!_progressItems) {
    _progressItems = [[NSMutableArray alloc] init];
  }
  NSDictionary *progressItem = @{
    cxFilenameKey : url.lastPathComponent,
    progressSubscribableKey : progressSubscribable
  };
  [_progressItems addObject:progressItem];
  
  [self didChangeValueForKey:@"progressItems"];
  
  // RAC
  @weakify(self);
  [[progressSubscribable finally:^{
    @strongify(self);
    // Remove the progress item when it completes
    [self willChangeValueForKey:@"progressItems"];
    [self->_progressItems removeObject:progressItem];
    [self didChangeValueForKey:@"progressItems"];
  }] subscribeCompleted:^{
    // Nothing
  }];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
  UITableViewCell *cell = nil;
  
  if ([directoryItem objectForKey:progressSubscribableKey] == nil) {
    HighlightTableViewCell *highlightCell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell = highlightCell;
    highlightCell.textLabelHighlightedCharacters = _filteredItemsHitMasks ? [_filteredItemsHitMasks objectAtIndex:indexPath.row] : nil;
  } else {
    static NSString * const progressCellIdentifier = @"progressCell";
    ProgressTableViewCell *progressCell = [tableView dequeueReusableCellWithIdentifier:progressCellIdentifier];
    if (!progressCell) {
      progressCell = [[ProgressTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:progressCellIdentifier];
    }
    cell = progressCell;
    [progressCell setProgressSubscribable:[directoryItem objectForKey:progressSubscribableKey]];
  }
  
  cell.textLabel.text = [directoryItem objectForKey:cxFilenameKey];
  if ([directoryItem objectForKey:NSFileType] == NSFileTypeDirectory)
  {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  }
  else
  {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.editingAccessoryType = UITableViewCellAccessoryNone;
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[[directoryItem objectForKey:cxFilenameKey] pathExtension]];
  }
  // TODO also use NSFileSize
  // Select item to maintain selection on filtering
  if ([_selectedItems containsObject:directoryItem])
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
  return [directoryItem objectForKey:progressSubscribableKey] == nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
  RemoteFileListController *remoteFileListController = [[RemoteFileListController alloc] init];
  [remoteFileListController prepareWithConnection:self.connection artCodeRemote:_remote path:[self.remotePath stringByAppendingPathComponent:[directoryItem objectForKey:cxFilenameKey]]];
  [remoteFileListController setEditing:self.editing animated:NO];
  [self.navigationController pushViewController:remoteFileListController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.isEditing) {
    NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
    if ([directoryItem objectForKey:NSFileType] == NSFileTypeDirectory) {
      // Same action as accessory button
      [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    } else {
      //[self _toolEditExportAction:nil];
    }
  } else {
    [self willChangeValueForKey:@"selectedItems"];
    [_selectedItems addObject:[self.filteredItems objectAtIndex:indexPath.row]];
    [self didChangeValueForKey:@"selectedItems"];
  }
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.isEditing) {
    [self willChangeValueForKey:@"selectedItems"];
    [_selectedItems removeObject:[self.filteredItems objectAtIndex:indexPath.row]];
    [self didChangeValueForKey:@"selectedItems"];
  }
  [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self tableView:tableView canEditRowAtIndexPath:indexPath] ? indexPath : nil;
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

- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

@end
