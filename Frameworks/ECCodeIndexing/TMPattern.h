//
//  TMPattern.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OnigRegexp;

@interface TMPattern : NSObject <NSCopying>

- (NSString *)name;
- (NSString *)contentName;
- (OnigRegexp *)match;
- (NSDictionary *)captures;
- (OnigRegexp *)begin;
- (OnigRegexp *)end;
- (NSDictionary *)beginCaptures;
- (NSDictionary *)endCaptures;
- (NSArray *)patterns;

@end
