//
//  TMSyntax.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECFileBuffer;

@interface TMSyntax : NSObject <NSDiscardableContent>

/// A dictionary containing all syntaxes indexed by scopeIdentifier
+ (NSDictionary *)allSyntaxes;
+ (TMSyntax *)syntaxWithScope:(NSString *)scope;
+ (TMSyntax *)syntaxForFileBuffer:(ECFileBuffer *)fileBuffer;

- (id)initWithFileURL:(NSURL *)fileURL;

- (NSString *)name;
- (NSString *)scopeIdentifier;

/// Content:
- (NSDictionary *)repository;
- (NSArray *)patterns;

@end

