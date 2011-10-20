//
//  TMPattern.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMPattern : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSRegularExpression *match;
@property (nonatomic, strong, readonly) NSRegularExpression *begin;
@property (nonatomic, strong, readonly) NSRegularExpression *end;
@property (nonatomic, strong, readonly) NSDictionary *captures;
@property (nonatomic, strong, readonly) NSArray *patterns;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSTextCheckingResult *)firstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;

@end