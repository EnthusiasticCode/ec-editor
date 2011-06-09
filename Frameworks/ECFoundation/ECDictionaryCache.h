//
//  ECDictionaryCache.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 25/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ECDictionaryCache : NSObject

@property (nonatomic, readonly) NSUInteger countLimit;

- (id)initWithCountLimit:(NSUInteger)limit;

- (void)setObject:(id)obj forKey:(id)key;
- (id)objectForKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

@end
