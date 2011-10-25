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

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) OnigRegexp *match;
@property (nonatomic, strong, readonly) NSDictionary *captures;
@property (nonatomic, strong, readonly) OnigRegexp *begin;
@property (nonatomic, strong, readonly) OnigRegexp *end;
@property (nonatomic, strong, readonly) NSDictionary *beginCaptures;
@property (nonatomic, strong, readonly) NSDictionary *endCaptures;
@property (nonatomic, strong, readonly) NSArray *patterns;
@property (nonatomic, strong, readonly) NSString *include;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
