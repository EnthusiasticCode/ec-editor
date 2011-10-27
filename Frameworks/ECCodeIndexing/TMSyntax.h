//
//  TMSyntax.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMPattern, OnigRegexp;

@interface TMSyntax : NSObject <NSDiscardableContent>

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *scope;
@property (nonatomic, strong, readonly) NSArray *fileTypes;
@property (nonatomic, strong, readonly) OnigRegexp *firstLineMatch;

- (id)initWithFileURL:(NSURL *)fileURL;

/// Content:
@property (nonatomic, strong, readonly) TMPattern *pattern;
@property (nonatomic, strong, readonly) NSDictionary *repository;

@end
