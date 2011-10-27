//
//  TMPattern.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OnigRegexp;

@interface TMPattern : NSObject

- (NSString *)name;
- (OnigRegexp *)match;
- (NSDictionary *)captures;
- (OnigRegexp *)begin;
- (OnigRegexp *)end;
- (NSDictionary *)beginCaptures;
- (NSDictionary *)endCaptures;
- (NSArray *)patterns;
- (NSString *)include;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
