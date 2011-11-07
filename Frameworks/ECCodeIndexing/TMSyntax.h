//
//  TMSyntax.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMSyntax : NSObject <NSDiscardableContent>

+ (TMSyntax *)syntaxWithScope:(NSString *)scope;
+ (TMSyntax *)syntaxForFile:(NSURL *)fileURL;

- (NSString *)name;
- (NSString *)scope;
/// Content:
- (NSArray *)patterns;

@end

