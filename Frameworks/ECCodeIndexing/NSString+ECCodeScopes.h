//
//  NSString+ECCodeScopes.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ECCodeScopes)

- (BOOL)containsScope:(NSString *)scopeIdentifier;

@end
