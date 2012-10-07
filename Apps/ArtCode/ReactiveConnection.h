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

/// A subscribable that returns \c RACTuple of path to array of dictionaries with directory item informations
- (RACSubscribable *)directoryContentsForPath:(NSString *)path;

/// A subscribable yielding the transcript records as \c RACTuples containing \c CKTranscriptType and the string for that transcript.
- (RACSubscribable *)transcript;

@end
