//
//  TMSyntax+Internal.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMSyntax.h"

@interface TMSyntax (Internal)

+ (void)loadAllSyntaxes;

/// Content:
- (NSDictionary *)repository;
- (NSArray *)patternsDictionaries;

@end
