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
  [_connection disconnect];
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

- (RACSubscribable *)directoryContentsForPath:(NSString *)path {
  if (!_directoryContentsSubject) {
    _directoryContentsSubject = [RACSubject subject];
  }
  [_connection changeToDirectory:path];
  [_connection directoryContents];
  return _directoryContentsSubject;
}

#pragma mark - Connection delegate

- (void)connection:(id <CKPublishingConnection>)con didConnectToHost:(NSString *)host error:(NSError *)error {
  if (error) {
    [_connectedSubject sendError:error];
  } else {
    [_connectedSubject sendNext:@YES];
    [_connectedSubject sendCompleted];
  }
  self.connected = YES;
}

- (void)connection:(id <CKPublishingConnection>)con didDisconnectFromHost:(NSString *)host {
  [_connectedSubject sendNext:@NO];
  [_connectedSubject sendCompleted];
  _connectedSubject = nil;
  self.connected = NO;
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveError:(NSError *)error {
  // TODO manage error
  NSLog(@"%@", [error localizedDescription]);
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

- (void)connection:(id <CKPublishingConnection>)con didChangeToDirectory:(NSString *)dirPath error:(NSError *)error {

}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error {
  if (!error) {
    [_directoryContentsSubject sendNext:[RACTuple tupleWithObjects:dirPath, contents, nil]];
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
  [_transcriptSubject sendNext:[RACTuple tupleWithObjects:[NSNumber numberWithInt:transcript], string, nil]];
}
@end
