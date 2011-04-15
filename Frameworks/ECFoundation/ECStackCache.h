//
//  ECStackBuffer.h
//  edit
//
//  Created by Uri Baghin on 4/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// A simple collection object for caching.
@interface ECStackCache : NSObject
/// Preferred size of the cache.
@property (nonatomic) NSUInteger cacheSize;
/// Target of the message to send if the cache is empty and an object is requested.
@property (nonatomic, assign) id target;
/// Selector of the message to send if the cache is emtpy and an object is requested.
/// The signature must be - (id)generateObjectForCache:(ECStackCache *)cache;
@property (nonatomic) SEL action;
/// Initializes the cache
- (id)initWithTarget:(id)target action:(SEL)action size:(NSUInteger)size;
/// Returns the number of objects in the cache
- (NSUInteger)count;
/// Returns a cached object, or a newly generated object if the cache is empty.
- (id)pop;
/// Caches an object if the cache is not full.
- (void)push:(id)object;
@end
