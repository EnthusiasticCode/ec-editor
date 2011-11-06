//
//  TMPattern+Internal.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMPattern.h"

@class TMSyntax;

@interface TMPattern (Internal)

+ (NSArray *)patternsWithSyntax:(TMSyntax *)syntax inDictionary:(NSDictionary *)dictionary;

@end
