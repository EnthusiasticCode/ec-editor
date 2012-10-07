//
//  ReactiveConnection.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/10/12.
//
//

#import <Foundation/Foundation.h>

@interface ReactiveConnection : NSObject

+ (ReactiveConnection *)reactiveConnectionWithURL:(NSURL *)url;

/// The URL at which the URL will operate
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, readonly, getter = isConnected) BOOL connected;

/// Begin a connections request if neccessary.
/// Returns a subscribable that yield a single boolean value with the connected status.
- (RACSubscribable *)connectWithCredentials:(NSURLCredential *)credentials;

/// A subscribable that returns \c RACTuple of path to array of dictionaries with directory item informations
- (RACSubscribable *)directoryContentsForPath:(NSString *)path;

/// A subscribable yielding the transcript records as \c RACTuples containing \c CKTranscriptType and the string for that transcript.
- (RACSubscribable *)transcript;

@end
