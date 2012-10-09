//
//  ReactiveConnection.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/10/12.
//
//

#import "ReactiveConnection.h"
#import <Connection/CKConnectionRegistry.h>

@interface ReactiveConnection ()
@property (nonatomic, readwrite, getter = isConnected) BOOL connected;
@end

@implementation ReactiveConnection {
  id<CKConnection> _connection;
  NSURLCredential *_connectCredentials;
  
  RACAsyncSubject *_connectedSubject;
  RACSubject *_transcriptSubject;
  RACSubject *_directoryContentsSubject;
  RACReplaySubject *_connectionStatusSubject;
}

+ (ReactiveConnection *)reactiveConnectionWithURL:(NSURL *)url {
  return [[self alloc] initWithURL:url];
}

- (id)initWithURL:(NSURL *)url {
  self = [super init];
  if (!self) {
    return nil;
  }
  _url = url;
  _connection = (id<CKConnection>)[[CKConnectionRegistry sharedConnectionRegistry] connectionWithRequest:[NSURLRequest requestWithURL:url]];
  [_connection setDelegate:self];
  return self;
}

- (void)dealloc {
  [_connection setDelegate:nil];
  [_connection disconnect];
}

#pragma mark - Properties

- (void)setConnected:(BOOL)connected {
  if (connected == _connected) {
    return;
  }
  
  _connected = connected;
  
  if (connected) {
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusConnected)];
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusIdle)];
  } else {
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusDisconnected)];
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusUnavailable)];
  }
}

#pragma mark - Public Methods

- (RACSubscribable *)connectionStatus {
  if (!_connectionStatusSubject) {
    _connectionStatusSubject = [RACReplaySubject replaySubjectWithCapacity:1];
  }
  return _connectionStatusSubject;
}

- (RACSubscribable *)connectWithCredentials:(NSURLCredential *)credentials {
  if (!_connectedSubject) {
    _connectCredentials = credentials;
    _connectedSubject = [RACAsyncSubject subject];
    [_connection connect];
  }
  return [_connectedSubject deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (RACSubscribable *)transcript {
  if (!_transcriptSubject) {
    _transcriptSubject = [RACSubject subject];
  }
  return _transcriptSubject;
}

- (RACSubscribable *)directoryContents {
  if (!_directoryContentsSubject) {
    _directoryContentsSubject = [RACSubject subject];
  }
  return _directoryContentsSubject;
}

- (void)changeToDirectory:(NSString *)path {
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusLoading)];
  [_connection changeToDirectory:path];
  [_connection directoryContents];
}

#pragma mark - Connection delegate

- (void)connection:(id <CKPublishingConnection>)con didConnectToHost:(NSString *)host error:(NSError *)error {
  if (error) {
    [_connectedSubject sendError:error];
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusError)];
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusUnavailable)];
  } else {
    [_connectedSubject sendNext:@YES];
    [_connectedSubject sendCompleted];
    self.connected = YES;
  }
}

- (void)connection:(id <CKPublishingConnection>)con didDisconnectFromHost:(NSString *)host {
  [_connectedSubject sendNext:@NO];
  [_connectedSubject sendCompleted];
  _connectedSubject = nil;
  self.connected = NO;
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveError:(NSError *)error {
  // TODO manage error
  NSLog(@"connection error: %@", [error localizedDescription]);
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusError)];
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusUnavailable)];
}

#pragma mark Connection Authentication

- (void)connection:(id <CKPublishingConnection>)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  [[challenge sender] useCredential:_connectCredentials forAuthenticationChallenge:challenge];
  _connectCredentials = nil;
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

//- (void)connection:(id <CKPublishingConnection>)con didChangeToDirectory:(NSString *)dirPath error:(NSError *)error {
//
//}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error {
  if (!error) {
    [_directoryContentsSubject sendNext:[RACTuple tupleWithObjects:dirPath, contents, nil]];
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusIdle)];
  } else {
    NSLog(@"connection receive content: %@", [error localizedDescription]);
    [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusError)];
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
  [_transcriptSubject sendNext:[RACTuple tupleWithObjects:[NSNumber numberWithInt:transcript], string, nil]];
}
@end
