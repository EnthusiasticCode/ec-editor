//
//  RemoteLoginController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import "RemoteLoginController.h"
#import "ArtCodeRemote.h"
#import <Connection/CKConnectionRegistry.h>
#import "Keychain.h"

#import "RemoteNavigationController.h"
#import "RemoteFileListController.h"

@implementation RemoteLoginController {
  ArtCodeRemote *_remote;
  id<CKConnection> _connection;
  BOOL _keychainUsed;
  NSURLCredential *_loginCredential;
}

- (id)initAndConnectToArtCodeRemote:(ArtCodeRemote *)remote {
  self = [super initWithNibName:@"RemoteLogin" bundle:nil];
  if (!self)
    return nil;
  _remote = remote;
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.loadingView.frame = self.view.bounds;
  [self _connectToURL:_remote.url];
}

- (void)setLoading:(BOOL)loading {
  self.loadingView.hidden = !loading;
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
  NSLog(@"%@", [error localizedDescription]);
}

#pragma mark Connection Authentication

- (void)connection:(id <CKPublishingConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  //self.loading = YES;
  
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
    [self setLoading:YES];
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

- (void)_connectToURL:(NSURL *)url {
  ASSERT(!_connection); // This should only be called once.
  [self setLoading:YES];
  _keychainUsed = NO;
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  _connection = (id<CKConnection>)[[CKConnectionRegistry sharedConnectionRegistry] connectionWithRequest:request];
  [_connection setDelegate:self];
  [_connection connect];
}

/// This methos setup the connection to the underlying navigation controller and pushes the brwser controller
- (void)_connectionSuccessfull {
  ASSERT(_connection);
  self.remoteNavigationController.connection = _connection;
  
  RemoteFileListController *remoteFileListController = [[RemoteFileListController alloc] initWithArtCodeRemote:_remote connection:_connection path:_remote.path];
  [self.remoteNavigationController pushViewController:remoteFileListController animated:YES];
}

@end
