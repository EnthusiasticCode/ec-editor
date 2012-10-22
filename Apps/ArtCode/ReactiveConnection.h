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

/// The URL at which the URL will operate
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, readonly, getter = isConnected) BOOL connected;

/// Returns the status of the connection with \c NSNumber containing a \c ReactiveConnectionStatus enum value.
- (RACSubscribable *)connectionStatus;

/// Begin a connections request if neccessary.
/// Returns a subscribable that yield a single boolean value with the connected status.
- (RACSubscribable *)connectWithCredentials:(NSURLCredential *)credentials;

/// A subscribable yielding the transcript records as \c RACTuples containing \c CKTranscriptType and the string for that transcript.
- (RACSubscribable *)transcript;

#pragma mark Managing directories

/// A subscribable that returns \c RACTuple of path to array of dictionaries with directory item informations
- (RACSubscribable *)directoryContents;
- (void)changeToDirectory:(NSString *)path;
- (RACSubscribable *)directoryContentsForDirectory:(NSString *)path;

#pragma mark Managin file transfers

/// Returns a subscribable that send next when a download update is available.
/// An update can be either an NSNumber containing the percentage of download complete of an NSURL of the localy downloaded file.
- (RACSubscribable *)downloadFileWithRemotePath:(NSString *)remotePath isDirectory:(BOOL)isDirectory;

/// The local URL will be querried to see if it's a directory to enable recursive upload.
/// Returns a subscribable that send next when an upload update is available.
/// An update is an NSNumber containing the percentage of upload completed.
- (RACSubscribable *)uploadFileAtLocalURL:(NSURL *)localURL toRemotePath:(NSString *)remotePath;

/// Returns a subscribable that send completed when a deleting operation ends.
- (RACSubscribable *)deleteFileWithRemotePath:(NSString *)remotePath;

@end
