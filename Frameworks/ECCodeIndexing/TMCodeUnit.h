//
//  TMCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"

@class TMSyntax;

@interface TMCodeUnit : NSObject <ECCodeParser>

- (id)initWithFileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax;

@end
