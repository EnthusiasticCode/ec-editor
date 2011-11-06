//
//  TMCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit+Subclass.h"

@class TMSyntax;

@interface TMCodeUnit : ECCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index fileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax;

@end
