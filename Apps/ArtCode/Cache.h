//
//  Cache.h
//  Foundation
//
//  Created by Uri Baghin on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cache : NSCache <NSFastEnumeration>

- (NSUInteger)count;
- (NSEnumerator *)keyEnumerator;
- (NSEnumerator *)objectEnumerator;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block;
- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id key, id obj, BOOL *stop))block;

@end
