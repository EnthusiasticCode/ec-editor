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
  NSMutableDictionary *_deleteProgressSubscribables;
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

- (void)cancelAll {
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusLoading)];
  [_connection cancelAll];
  NSError *cancelError = [[NSError alloc] init];
  [_downloadProgressSubscribables enumerateKeysAndObjectsUsingBlock:^(id key, RACSubject *subject, BOOL *stop) {
    [subject sendError:cancelError];
  }];
  [_downloadProgressSubscribables removeAllObjects];
  [_uploadProgressSubscribables enumerateKeysAndObjectsUsingBlock:^(id key, RACSubject *subject, BOOL *stop) {
    [subject sendError:cancelError];
  }];
  [_uploadProgressSubscribables removeAllObjects];
  [_deleteProgressSubscribables enumerateKeysAndObjectsUsingBlock:^(id key, RACSubject *subject, BOOL *stop) {
    [subject sendError:cancelError];
  }];
  [_deleteProgressSubscribables removeAllObjects];
  for (NSURL *tempURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] includingPropertiesForKeys:nil options:0 error:NULL]) {
    [[NSFileManager defaultManager] removeItemAtURL:tempURL error:NULL];
  }
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusIdle)];
}

- (RACSubscribable *)directoryContents {
  return _directoryContentsSubject ?: (_directoryContentsSubject = [RACSubject subject]);
}

- (void)changeToDirectory:(NSString *)path {
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusLoading)];
  [_connection changeToDirectory:path];
  [_connection directoryContents];
}

- (RACSubscribable *)directoryContentsForDirectory:(NSString *)path {
  @weakify(self);
  return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self changeToDirectory:path];
    return [[[[[self directoryContents]
               where:^BOOL(RACTuple *x) {
                 return [x.first isEqualToString:path]; }]
               select:^id(RACTuple *x) {
                 return x.second; }]
               take:1]
               subscribe:subscriber];
  }];
}

- (RACSubscribable *)downloadFileWithRemotePath:(NSString *)remotePath isDirectory:(BOOL)isDirectory {
  if (!_downloadProgressSubscribables) {
    _downloadProgressSubscribables = [[NSMutableDictionary alloc] init];
  }
  if (isDirectory) {
    return [self _downloadDirectoryWithRemotePath:remotePath toLocalURL:[NSURL temporaryDirectory]];
  } else {
    return [self _downloadFileWithRemotePath:remotePath toLocalURL:[NSURL temporaryFileURL]];
  }
}

- (RACSubscribable *)_downloadFileWithRemotePath:(NSString *)remotePath toLocalURL:(NSURL *)localURL {
  @weakify(self);
  return [[[RACSubscribable createSubscribable:^(id<RACSubscriber> subscriber) {
    @strongify(self);
    // On Subscription, start the download
    RACSubject *downloadSubscribable = [RACSubject subject];
    [self->_downloadProgressSubscribables setObject:downloadSubscribable forKey:remotePath];
    [self->_connection downloadFile:remotePath toDirectory:localURL.path overwrite:YES delegate:nil];
    // Retun an 'endWith:localURL' subscribable
		return [downloadSubscribable
            subscribeNext:^(id x) {
              [subscriber sendNext:x];
            } error:^(NSError *error) {
              // Remove temporary file
              [[NSFileManager defaultManager] removeItemAtURL:localURL error:&error];
              [subscriber sendError:error];
            } completed:^{
              // Send temporary download URL uppon completion
              [subscriber sendNext:localURL];
              [subscriber sendCompleted];
            }];
	}] publish] autoconnect];
}

- (RACSubscribable *)_downloadDirectoryWithRemotePath:(NSString *)remotePath toLocalURL:(NSURL *)localURL {
  @weakify(self);
  return [[[RACSubscribable createSubscribable:^(id<RACSubscriber> subscriber) {
    @strongify(self);
    // Create destination directory
    [[NSFileManager defaultManager] createDirectoryAtURL:localURL withIntermediateDirectories:YES attributes:nil error:NULL];
    // Returning a subscribable that 'endWith:localURL'
    __block NSUInteger totalExpected = 0;
    __block NSUInteger totalAccumulator = 0;
    return [[[[self directoryContentsForDirectory:remotePath]
              // Transform the directory content into subscribable
              selectMany:^id(NSArray *content) {
                totalExpected = content.count;
                return [content rac_toSubscribable];
              }]
              // Get a merge of all 
              selectMany:^id(NSDictionary *item) {
                @strongify(self);
                NSString *itemName = [item objectForKey:cxFilenameKey];
                NSString *itemRemotePath = [remotePath stringByAppendingPathComponent:itemName];
                NSURL *itemLocalURL = [localURL URLByAppendingPathComponent:itemName isDirectory:YES];
                // For every item in the directory, return the progress subscribable
                if ([item objectForKey:NSFileType] == NSFileTypeDirectory) {
                  return [self _downloadDirectoryWithRemotePath:itemRemotePath toLocalURL:itemLocalURL];
                } else {
                  return [self _downloadFileWithRemotePath:itemRemotePath toLocalURL:itemLocalURL];
                }
              }] subscribeNext:^(id x) {
                // Ignore progress nexts, only consider completed files
                if ([x isKindOfClass:[NSURL class]]) {
                  totalAccumulator++;
                  [subscriber sendNext:@(totalAccumulator * 100 / totalExpected)];
                }
              } error:^(NSError *error) {
                // Remove temporary file
                [[NSFileManager defaultManager] removeItemAtURL:localURL error:&error];
                [subscriber sendError:error];
              } completed:^{
                // Send temporary download URL uppon completion
                [subscriber sendNext:localURL];
                [subscriber sendCompleted];
              }];
  }] publish] autoconnect];
}

- (RACSubscribable *)uploadFileAtLocalURL:(NSURL *)localURL toRemotePath:(NSString *)remotePath {
  // TODO recursive option
  if (!_uploadProgressSubscribables) {
    _uploadProgressSubscribables = [[NSMutableDictionary alloc] init];
  }
  RACSubject *uploadSubscribable = [RACSubject subject];
  [_uploadProgressSubscribables setObject:uploadSubscribable forKey:remotePath];
  [_connection uploadFileAtURL:localURL toPath:remotePath openingPosixPermissions:0];
  return uploadSubscribable;
}

- (RACSubscribable *)deleteFileWithRemotePath:(NSString *)remotePath {
  if (!_deleteProgressSubscribables) {
    _deleteProgressSubscribables = [[NSMutableDictionary alloc] init];
  }
  RACSubject *deleteSubscribable = [RACSubject subject];
  [_deleteProgressSubscribables setObject:deleteSubscribable forKey:remotePath];
  [_connection deleteFile:remotePath];
  return deleteSubscribable;
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

#pragma mark Connection Deletion

- (void)connection:(id <CKPublishingConnection>)con didDeleteFile:(NSString *)path error:(NSError *)error {
  RACSubject *subject = [_deleteProgressSubscribables objectForKey:path];
  if (error) {
    [subject sendError:error];
  } else {
    [subject sendCompleted];
  }
  [_deleteProgressSubscribables removeObjectForKey:path];
}

@end
