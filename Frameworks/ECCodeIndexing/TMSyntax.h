//
//  TMSyntax.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECAttributedUTF8FileBuffer;

@interface TMSyntax : NSObject <NSDiscardableContent>

+ (TMSyntax *)syntaxWithScope:(NSString *)scope;
+ (TMSyntax *)syntaxForFileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer;

- (NSString *)name;
- (NSString *)scope;
/// Content:
- (NSArray *)patterns;

@end

