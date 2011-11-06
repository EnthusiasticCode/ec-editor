//
//  TMToken.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"

@class TMScope;

@interface TMToken : NSObject <ECCodeToken, ECCodeCursor>

- (id)initWithContainingString:(NSString *)containingString range:(NSRange)range scope:(TMScope *)scope;

@end
