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
  
  RACSubject *_connectedSubject;
  RACSubject *_transcriptSubject;
  RACSubject *_directoryContentsSubject;
  RACReplaySubject *_connectionStatusSubject;
  
  NSMutableDictionary *_downloadProgressSignals;
  NSMutableDictionary *_uploadProgressSignals;
  NSMutableDictionary *_deleteProgressSignals;
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

- (RACSignal *)connectionStatus {
  return _connectionStatusSubject ?: (_connectionStatusSubject = [RACReplaySubject replaySubjectWithCapacity:1]);
}

- (RACSignal *)connectWithCredentials:(NSURLCredential *)credentials {
  if (!_connectedSubject) {
    _connectCredentials = credentials;
    // TODO: This should be a replay subject
    _connectedSubject = [RACReplaySubject replaySubjectWithCapacity:1];
    // TODO: this should connect when someone subscribe to the subject
    _connection = (id<CKConnection>)[[CKConnectionRegistry sharedConnectionRegistry] connectionWithRequest:[NSURLRequest requestWithURL:self.url]];
    [_connection setDelegate:self];
    ASSERT(_connection);
    [_connection connect];
  }
	ASSERT(RACScheduler.currentScheduler);
  return [_connectedSubject deliverOn:RACScheduler.currentScheduler];
}

- (RACSignal *)transcript {
  return _transcriptSubject ?: (_transcriptSubject = [RACSubject subject]);
}

- (void)cancelAll {
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusLoading)];
  [_connection cancelAll];
  NSError *cancelError = [[NSError alloc] init];
  [_downloadProgressSignals enumerateKeysAndObjectsUsingBlock:^(id key, RACSubject *subject, BOOL *stop) {
    [subject sendError:cancelError];
  }];
  [_downloadProgressSignals removeAllObjects];
  [_uploadProgressSignals enumerateKeysAndObjectsUsingBlock:^(id key, RACSubject *subject, BOOL *stop) {
    [subject sendError:cancelError];
  }];
  [_uploadProgressSignals removeAllObjects];
  [_deleteProgressSignals enumerateKeysAndObjectsUsingBlock:^(id key, RACSubject *subject, BOOL *stop) {
    [subject sendError:cancelError];
  }];
  [_deleteProgressSignals removeAllObjects];
  for (NSURL *tempURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] includingPropertiesForKeys:nil options:0 error:NULL]) {
    [[NSFileManager defaultManager] removeItemAtURL:tempURL error:NULL];
  }
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusIdle)];
}

- (RACSignal *)directoryContents {
  return _directoryContentsSubject ?: (_directoryContentsSubject = [RACSubject subject]);
}

- (void)changeToDirectory:(NSString *)path {
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusLoading)];
  [_connection changeToDirectory:path];
  [_connection directoryContents];
}

- (RACSignal *)directoryContentsForDirectory:(NSString *)path {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self changeToDirectory:path];
    return [[[[[self directoryContents]
               filter:^BOOL(RACTuple *x) {
                 return [x.first isEqualToString:path]; }]
               map:^id(RACTuple *x) {
                 return x.second; }]
               take:1]
               subscribe:subscriber];
  }];
}

- (RACSignal *)downloadFileWithRemotePath:(NSString *)remotePath isDirectory:(BOOL)isDirectory {
  if (!_downloadProgressSignals) {
    _downloadProgressSignals = [[NSMutableDictionary alloc] init];
  }
  if (isDirectory) {
    return [self _downloadDirectoryWithRemotePath:remotePath toLocalURL:[NSURL temporaryDirectory]];
  } else {
    return [self _downloadFileWithRemotePath:remotePath toLocalURL:[NSURL temporaryFileURL]];
  }
}

- (RACSignal *)_downloadFileWithRemotePath:(NSString *)remotePath toLocalURL:(NSURL *)localURL {
  @weakify(self);
  return [[[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
    @strongify(self);
    // On Subscription, start the download
    RACSubject *downloadSignal = [RACSubject subject];
    self->_downloadProgressSignals[remotePath] = downloadSignal;
    [self->_connection downloadFile:remotePath toDirectory:localURL.path overwrite:YES delegate:nil];
    // Retun an 'endWith:localURL' signal
		return [downloadSignal
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

- (RACSignal *)_downloadDirectoryWithRemotePath:(NSString *)remotePath toLocalURL:(NSURL *)localURL {
  @weakify(self);
  return [[[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
    @strongify(self);
    // Create destination directory
    [[NSFileManager defaultManager] createDirectoryAtURL:localURL withIntermediateDirectories:YES attributes:nil error:NULL];
    // Returning a signal that 'endWith:localURL'
    __block NSUInteger totalExpected = 0;
    __block NSUInteger totalAccumulator = 0;
    return [[[self directoryContentsForDirectory:remotePath] flattenMap:^id(NSArray *content) {
      totalExpected = content.count;
      return [[content map:^id<RACSignal>(NSDictionary *item) {
        @strongify(self);
        NSString *itemName = item[cxFilenameKey];
        NSString *itemRemotePath = [remotePath stringByAppendingPathComponent:itemName];
        NSURL *itemLocalURL = [localURL URLByAppendingPathComponent:itemName isDirectory:YES];
        // For every item in the directory, return the progress signal
        if (item[NSFileType] == NSFileTypeDirectory) {
          return [self _downloadDirectoryWithRemotePath:itemRemotePath toLocalURL:itemLocalURL];
        } else {
          return [self _downloadFileWithRemotePath:itemRemotePath toLocalURL:itemLocalURL];
        }
      }] map:^id<RACSignal>(id<RACSignal> x) {
        return [x doNext:^(id y) {
          // Ignore progress nexts, only consider completed files
          if ([y isKindOfClass:[NSURL class]]) {
            totalAccumulator++;
            [subscriber sendNext:@(totalAccumulator * 100 / totalExpected)];
          }
        }];
      }];
    }] subscribeError:^(NSError *error) {
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

- (RACSignal *)uploadFileAtLocalURL:(NSURL *)localURL toRemotePath:(NSString *)remotePath {
  // TODO: recursive option
  if (!_uploadProgressSignals) {
    _uploadProgressSignals = [[NSMutableDictionary alloc] init];
  }
  if ([localURL isDirectory]) {
    return [self _uploadDirectoryAtURL:localURL toRemotePath:remotePath];
  } else {
    return [self _uploadFileAtLocalURL:localURL toRemotePath:remotePath];
  }
}

- (RACSignal *)_uploadFileAtLocalURL:(NSURL *)localURL toRemotePath:(NSString *)remotePath {
  RACSubject *uploadSignal = [RACSubject subject];
  _uploadProgressSignals[remotePath] = uploadSignal;
  [_connection uploadFileAtURL:localURL toPath:remotePath openingPosixPermissions:0];
  return uploadSignal;
}

- (RACSignal *)_uploadDirectoryAtURL:(NSURL *)localURL toRemotePath:(NSString *)remotePath {
  @weakify(self);
  return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    // Create remote directory
    [self->_connection createDirectoryAtPath:[remotePath stringByAppendingPathComponent:localURL.lastPathComponent] posixPermissions:nil];
    // Recursevly upload
    NSArray *localContent = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:localURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 error:NULL];
    NSUInteger totalExpected = localContent.count;
    __block NSUInteger totalAccumulator = 0;
    return [[RACSignal zip:[[localContent map:^id<RACSignal>(NSURL *x) {
      @strongify(self);
      NSString *remoteX = [remotePath stringByAppendingPathComponent:x.lastPathComponent];
      if ([x isDirectory]) {
        return [self _uploadDirectoryAtURL:x toRemotePath:remoteX];
      } else {
        return [self _uploadFileAtLocalURL:x toRemotePath:remoteX];
      }
    }] map:^id<RACSignal>(id<RACSignal> x) {
      return [x doNext:^(id y) {
        if ([x isKindOfClass:[NSString class]]) {
          totalAccumulator++;
          [subscriber sendNext:@(totalAccumulator * 100 / totalExpected)];
        }
      }];
    }]] subscribeError:^(NSError *error) {
      [subscriber sendError:error];
    } completed:^{
      [subscriber sendNext:remotePath];
      [subscriber sendCompleted];
    }];
  }] publish] autoconnect];
}

- (RACSignal *)deleteFileWithRemotePath:(NSString *)remotePath {
  if (!_deleteProgressSignals) {
    _deleteProgressSignals = [[NSMutableDictionary alloc] init];
  }
  RACSubject *deleteSignal = [RACSubject subject];
  _deleteProgressSignals[remotePath] = deleteSignal;
  [_connection deleteFile:remotePath];
  return deleteSignal;
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
  _connectedSubject = nil;
}

- (void)connection:(id <CKPublishingConnection>)con didDisconnectFromHost:(NSString *)host {
  [_connectedSubject sendNext:@NO];
  [_connectedSubject sendCompleted];
  _connectedSubject = nil;
  self.connected = NO;
}

- (void)connection:(id <CKPublishingConnection>)con didReceiveError:(NSError *)error {
  NSLog(@"connection error: %@", [error localizedDescription]);
  [_connectionStatusSubject sendNext:@(ReactiveConnectionStatusError)];
  [_connectedSubject sendError:error];
  _connectedSubject = nil;
  self.connected = NO;
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
  [_transcriptSubject sendNext:[RACTuple tupleWithObjects:@(transcript), string, nil]];
}

#pragma mark Connection Downloads

- (void)connection:(id<CKConnection>)con downloadDidBegin:(NSString *)remotePath {
  [self connection:con download:remotePath progressedTo:@0];
}

- (void)connection:(id<CKConnection>)con download:(NSString *)remotePath progressedTo:(NSNumber *)percent {
  [_downloadProgressSignals[remotePath] sendNext:percent];
}

- (void)connection:(id<CKConnection>)con downloadDidFinish:(NSString *)remotePath error:(NSError *)error {
  RACSubject *subject = _downloadProgressSignals[remotePath];
  if (error) {
    [subject sendError:error];
  } else {
    [subject sendCompleted];
  }
  [_downloadProgressSignals removeObjectForKey:remotePath];
}

//- (void)connection:(id<CKConnection>)con download:(NSString *)path receivedDataOfLength:(unsigned long long)length {
//  
//}

#pragma mark Connection Uploads

- (void)connection:(id<CKPublishingConnection>)con uploadDidBegin:(NSString *)remotePath {
  [self connection:(id<CKConnection>)con upload:remotePath progressedTo:@0];
}

- (void)connection:(id<CKConnection>)con upload:(NSString *)remotePath progressedTo:(NSNumber *)percent {
  [_uploadProgressSignals[remotePath] sendNext:percent];
}

- (void)connection:(id<CKPublishingConnection>)con uploadDidFinish:(NSString *)remotePath error:(NSError *)error {
  RACSubject *subject = _uploadProgressSignals[remotePath];
  if (error) {
    [subject sendError:error];
  } else {
    [subject sendNext:remotePath];
    [subject sendCompleted];
  }
  [_uploadProgressSignals removeObjectForKey:remotePath];
}

#pragma mark Connection Deletion

- (void)connection:(id <CKPublishingConnection>)con didDeleteFile:(NSString *)path error:(NSError *)error {
  RACSubject *subject = _deleteProgressSignals[path];
  if (error) {
    [subject sendError:error];
  } else {
    [subject sendCompleted];
  }
  [_deleteProgressSignals removeObjectForKey:path];
}

@end
