//
//  ReactiveConnection.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/10/12.
//
//

#import "ReactiveConnection.h"
#import <Connection/CKConnectionRegistry.h>
#import "NSURL+Utilities.h"

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
  
  NSMutableDictionary *_downloadProgressSubscribables;
  NSMutableDictionary *_uploadProgressSubscribables;
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
  return _connectionStatusSubject ?: (_connectionStatusSubject = [RACReplaySubject replaySubjectWithCapacity:1]);
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
  return _transcriptSubject ?: (_transcriptSubject = [RACSubject subject]);
}

- (RACSubscribable *)directoryContents {
  return _directoryContentsSubject ?: (_directoryContentsSubject = [RACSubject subject]);
}

- (void)changeToDirectory:(NSString *)path {
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusLoading)];
  [_connection changeToDirectory:path];
  [_connection directoryContents];
}

- (RACSubscribable *)downloadFileWithRemotePath:(NSString *)remotePath isDirectory:(BOOL)isDirecotry {
  if (!_downloadProgressSubscribables) {
    _downloadProgressSubscribables = [[NSMutableDictionary alloc] init];
  }
  // Generate the temporary download URL
  NSURL *tempDownloadURL = isDirecotry ? [NSURL temporaryDirectory] : [NSURL temporaryFileURL];
  RACSubject *downloadSubscribable = [RACReplaySubject replaySubjectWithCapacity:1];
  [_downloadProgressSubscribables setObject:downloadSubscribable forKey:remotePath];
  // Run download
  if (isDirecotry) {
    [_connection recursivelyDownload:remotePath to:tempDownloadURL.absoluteString overwrite:YES];
  } else {
    [_connection downloadFile:remotePath toDirectory:tempDownloadURL.absoluteString overwrite:YES delegate:nil];
  }
  // Retun an 'endWith:tempDownloadURL' subscribable
  return [RACSubscribable createSubscribable:^(id<RACSubscriber> subscriber) {
		return [downloadSubscribable subscribeNext:^(id x) {
			[subscriber sendNext:x];
		} error:^(NSError *error) {
      // Remove temporary file
      [[NSFileManager defaultManager] removeItemAtURL:tempDownloadURL error:&error];
			[subscriber sendError:error];
		} completed:^{
      // Send temporary download URL uppon completion
      [subscriber sendNext:tempDownloadURL];
			[subscriber sendCompleted];
		}];
	}];
}

- (RACSubscribable *)uploadFileAtLocalURL:(NSURL *)localURL toRemotePath:(NSString *)remotePath {
  // TODO recursive option
  if (!_uploadProgressSubscribables) {
    _uploadProgressSubscribables = [[NSMutableDictionary alloc] init];
  }
  RACSubject *uploadSubscribable = [RACSubject subject];
  [_uploadProgressSubscribables setObject:uploadSubscribable forKey:remotePath];
  // TODO use proper permissions
  [_connection uploadFileAtURL:localURL toPath:remotePath openingPosixPermissions:0];
  return uploadSubscribable;
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

#pragma mark Connection Downloads

- (void)connection:(id<CKConnection>)con downloadDidBegin:(NSString *)remotePath {
  // TODO check if needed
  [self connection:con download:remotePath progressedTo:@0];
}

- (void)connection:(id<CKConnection>)con download:(NSString *)remotePath progressedTo:(NSNumber *)percent {
  [[_downloadProgressSubscribables objectForKey:remotePath] sendNext:percent];
}

- (void)connection:(id<CKConnection>)con downloadDidFinish:(NSString *)remotePath error:(NSError *)error {
  RACSubject *subject = [_downloadProgressSubscribables objectForKey:remotePath];
  if (error) {
    [subject sendError:error];
  } else {
    [subject sendCompleted];
  }
  [_downloadProgressSubscribables removeObjectForKey:remotePath];
}

//- (void)connection:(id<CKConnection>)con download:(NSString *)path receivedDataOfLength:(unsigned long long)length {
//  
//}

#pragma mark Connection Uploads

- (void)connection:(id<CKPublishingConnection>)con uploadDidBegin:(NSString *)remotePath {
  [self connection:(id<CKConnection>)con upload:remotePath progressedTo:@0];
}

- (void)connection:(id<CKConnection>)con upload:(NSString *)remotePath progressedTo:(NSNumber *)percent {
  [[_uploadProgressSubscribables objectForKey:remotePath] sendNext:percent];
}

- (void)connection:(id<CKPublishingConnection>)con uploadDidFinish:(NSString *)remotePath error:(NSError *)error {
  RACSubject *subject = [_uploadProgressSubscribables objectForKey:remotePath];
  if (error) {
    [subject sendError:error];
  } else {
    [subject sendCompleted];
  }
  [_uploadProgressSubscribables removeObjectForKey:remotePath];
}

@end
