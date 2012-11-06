//
//  RACSubscribable+libdispatch.h
//  ArtCode
//
//  Created by Uri Baghin on 11/5/12.
//
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSubscribable (libdispatch)

+ (RACSubscribable *)interval:(NSTimeInterval)interval withLeeway:(NSTimeInterval)leeway;

@end
