//
//  RACSignal+libdispatch.h
//  ArtCode
//
//  Created by Uri Baghin on 11/5/12.
//
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSignal (libdispatch)

+ (RACSignal *)interval:(NSTimeInterval)interval withLeeway:(NSTimeInterval)leeway;

@end
