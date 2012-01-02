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

+ (TMSyntax *)syntaxWithScope:(NSString *)scope;
+ (TMSyntax *)syntaxForFileBuffer:(ECFileBuffer *)fileBuffer;

- (NSString *)name;
- (NSString *)scopeIdentifier;
/// Content:
- (NSArray *)patterns;

@end

