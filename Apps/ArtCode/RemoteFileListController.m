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
#import "RACSignal+ScoreForAbbreviation.h"
#import "Keychain.h"

#import "RemoteNavigationController.h"
#import "HighlightTableViewCell.h"
#import "ProgressTableViewCell.h"
#import "UIImage+AppStyle.h"

static NSString * const progressSignalKey = @"progressSibscribable";

@interface RemoteFileListController ()
@property (nonatomic, strong) ReactiveConnection *connection;
@property (nonatomic, strong) NSURLCredential *authenticationCredentials;
@property (nonatomic, strong) NSString *remotePath;
@property (nonatomic, strong) NSArray *directoryContent;
@property (nonatomic) BOOL showLogin;
@property (nonatomic) BOOL showLoading;
@property (nonatomic, readwrite, copy) NSArray *selectedItems;
// An array of NSDictionaries with keys: cxFilenameKey, progressSignalKey
@property (nonatomic, strong) NSArray *progressItems;
@end


@implementation RemoteFileListController {
  ArtCodeRemote *_remote;
  
  BOOL _keychianAttemptUsed;
  NSURLAuthenticationChallenge *_authenticationChallenge;
  
  NSArray *_filteredItems;

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
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
  
  // RAC
  @weakify(self);
  
  // Directory content update reaction
  [[[[self.connection directoryContents] filter:^BOOL(RACTuple *pathAndContent) {
		@strongify(self);
		return [self.remotePath isEqualToString:pathAndContent.first];
	}] map:^(RACTuple *pathAndContent) {
		return pathAndContent.second;
	}] toProperty:@keypath(self.directoryContent) onObject:self];

	[[[RACSignal combineLatest:@[ RACAbleWithStart(self.directoryContent), RACAbleWithStart(self.progressItems) ] reduce:^(NSArray *directoryItems, NSArray *progressItems) {
		if (directoryItems.count == 0 && progressItems.count == 0) return (NSArray *)nil;
		return [(directoryItems ?: [[NSArray alloc] init]) arrayByAddingObjectsFromArray:progressItems];
	}] filterArraySignalByAbbreviation:self.searchBarTextSubject extrapolateTargetStringBlock:^NSString *(NSDictionary *item) {
		return item[cxFilenameKey];
	}] toProperty:@keypath(self.filteredItems) onObject:self];
	
  // Connected refresh reaction
  [RACAble(self.connection.connected) subscribeNext:^(id x) {
		@strongify(self);
    if ([x boolValue]) {
      [self refresh];
    } else {
      self.showLogin = YES;
    }
  }];
  
  // Connection status reaction
  [self.connection.connectionStatus subscribeNext:^(id x) {
    enum ReactiveConnectionStatus status = [x intValue];
    if (!self.showLogin) {
      self.showLoading = status == ReactiveConnectionStatusLoading;
    } else if (status == ReactiveConnectionStatusError) {
      self.showLoading = NO;
      self.showLogin = YES;
      // TODO: set error
    }
  }];
  
  RAC(self.loginErrorMessage.hidden) = [[self.connection.connectionStatus
                                        filter:^BOOL(id x) {
                                          enum ReactiveConnectionStatus status = [x intValue];
                                          return status == ReactiveConnectionStatusError || status == ReactiveConnectionStatusConnected;
                                        }]
                                        map:^id(id x) {
                                          return @((enum ReactiveConnectionStatus)[x intValue] == ReactiveConnectionStatusConnected);
                                        }];
  
  // Login reaction
  [[[RACAble(self.authenticationCredentials) map:^id(NSURLCredential *credentials) {
		@strongify(self);
		self.showLoading = YES;
		return [[self.connection connectWithCredentials:credentials] catchTo:[RACSignal return:@(NO)]];
	}] switchToLatest] subscribeNext:^(NSNumber *x) {
		@strongify(self);
		self.showLoading = NO;
		self.showLogin = !x.boolValue;
	}];
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
    _selectedItems = [NSMutableArray array];
  } else {
    _selectedItems = nil;
  }
  [self didChangeValueForKey:@"selectedItems"];
}

#pragma mark - Public methods

- (void)addProgressItemWithURL:(NSURL *)url progressSignal:(RACSignal *)progressSignal {
  [self willChangeValueForKey:@"progressItems"];
  if (!_progressItems) {
    _progressItems = [NSMutableArray array];
  }
  NSDictionary *progressItem = @{
    cxFilenameKey : url.lastPathComponent,
    progressSignalKey : progressSignal
  };
  [_progressItems addObject:progressItem];
  
  [self didChangeValueForKey:@"progressItems"];
  
  // RAC
  @weakify(self);
  [[progressSignal finally:^{
    @strongify(self);
    // Remove the progress item when it completes
    [self willChangeValueForKey:@"progressItems"];
    [self->_progressItems removeObject:progressItem];
    [self didChangeValueForKey:@"progressItems"];
  }] subscribeCompleted:^{
    // Nothing
  }];
}

- (void)refresh {
  [self.connection changeToDirectory:self.remotePath];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RACTupleUnpack(NSDictionary *directoryItem, NSIndexSet *hitMask) = self.filteredItems[indexPath.row];

  UITableViewCell *cell = nil;
  
  if (directoryItem[progressSignalKey] == nil) {
    HighlightTableViewCell *highlightCell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell = highlightCell;
    highlightCell.textLabelHighlightedCharacters = hitMask;
  } else {
    static NSString * const progressCellIdentifier = @"progressCell";
    ProgressTableViewCell *progressCell = [tableView dequeueReusableCellWithIdentifier:progressCellIdentifier];
    if (!progressCell) {
      progressCell = [[ProgressTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:progressCellIdentifier];
    }
    cell = progressCell;
    [progressCell setProgressSignal:directoryItem[progressSignalKey]];
  }
  
  cell.textLabel.text = directoryItem[cxFilenameKey];
  if (directoryItem[NSFileType] == NSFileTypeDirectory)
  {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  }
  else
  {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.editingAccessoryType = UITableViewCellAccessoryNone;
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[directoryItem[cxFilenameKey] pathExtension]];
  }
  // TODO: also use NSFileSize
  // Select item to maintain selection on filtering
  if ([_selectedItems containsObject:directoryItem])
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *directoryItem = [self.filteredItems[indexPath.row] first];
  return directoryItem[progressSignalKey] == nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *directoryItem = [self.filteredItems[indexPath.row] first];
  RemoteFileListController *remoteFileListController = [[UIStoryboard storyboardWithName:@"RemoteNavigator" bundle:nil] instantiateViewControllerWithIdentifier:@"RemoteFileListController"];
	[remoteFileListController prepareWithConnection:self.connection artCodeRemote:_remote path:[self.remotePath stringByAppendingPathComponent:directoryItem[cxFilenameKey]]];
  [remoteFileListController setEditing:self.editing animated:NO];
  [self.navigationController pushViewController:remoteFileListController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.isEditing) {
    NSDictionary *directoryItem = [self.filteredItems[indexPath.row] first];
    if (directoryItem[NSFileType] == NSFileTypeDirectory) {
      // Same action as accessory button
      [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    } else {
      //[self _toolEditExportAction:nil];
    }
  } else {
    [self willChangeValueForKey:@"selectedItems"];
    [_selectedItems addObject:[self.filteredItems[indexPath.row] first]];
    [self didChangeValueForKey:@"selectedItems"];
  }
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.isEditing) {
    [self willChangeValueForKey:@"selectedItems"];
    [_selectedItems removeObject:[self.filteredItems[indexPath.row] first]];
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
  } else {
    [self.loadingView removeFromSuperview];
  }
}

- (void)dismiss {
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
