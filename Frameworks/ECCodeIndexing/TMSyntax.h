//
//  TMSyntax.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMSyntax : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *scope;
@property (nonatomic, strong, readonly) NSArray *fileTypes;
@property (nonatomic, strong, readonly) NSRegularExpression *firstLineMatch;
@property (nonatomic, strong, readonly) NSArray *patterns;

- (id)initWithFileURL:(NSURL *)fileURL;

@end
