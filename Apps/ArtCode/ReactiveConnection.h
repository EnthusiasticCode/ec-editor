//
//  ReactiveConnection.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/10/12.
//
//

#import <Foundation/Foundation.h>

enum ReactiveConnectionStatus {
  ReactiveConnectionStatusUnavailable,   // The connection is unavailable, try connecting
  ReactiveConnectionStatusError,         // The connection received an error
  ReactiveConnectionStatusConnected,     // The connection just connected
  ReactiveConnectionStatusDisconnected,  // The connection just disconnected
  ReactiveConnectionStatusIdle,          // The connection is ready and waiting
  ReactiveConnectionStatusLoading        // The connection is performing an operation
};

@interface ReactiveConnection : NSObject

+ (ReactiveConnection *)reactiveConnectionWithURL:(NSURL *)url;

// The URL at which the URL will operate
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, readonly, getter = isConnected) BOOL connected;

// Returns the status of the connection with \c NSNumber containing a \c ReactiveConnectionStatus enum value.
- (RACSignal *)connectionStatus;

// Begin a connections request if neccessary.
// Returns a signal that yield a single boolean value with the connected status.
- (RACSignal *)connectWithCredentials:(NSURLCredential *)credentials;

// A signal yielding the transcript records as \c RACTuples containing \c CKTranscriptType and the string for that transcript.
- (RACSignal *)transcript;

// Cancel all the operations in progress.
- (void)cancelAll;

#pragma mark Managing directories

// A signal that returns \c RACTuple of path to array of dictionaries with directory item informations
- (RACSignal *)directoryContents;
- (void)changeToDirectory:(NSString *)path;
- (RACSignal *)directoryContentsForDirectory:(NSString *)path;

#pragma mark Managin file transfers

// Returns a signal that send next when a download update is available.
// An update can be either an NSNumber containing the percentage of download complete of an NSURL of the localy downloaded file.
- (RACSignal *)downloadFileWithRemotePath:(NSString *)remotePath isDirectory:(BOOL)isDirectory;

// The local URL will be querried to see if it's a directory to enable recursive upload.
// Returns a signal that send next when an upload update is available.
// An update is an NSNumber containing the percentage of upload completed.
- (RACSignal *)uploadFileAtLocalURL:(NSURL *)localURL toRemotePath:(NSString *)remotePath;

// Returns a signal that send completed when a deleting operation ends.
- (RACSignal *)deleteFileWithRemotePath:(NSString *)remotePath;

@end
