//
//  TMCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMCodeIndex.h"

@class TMSyntax;

@interface TMCodeParser : NSObject <ECCodeParser, NSDiscardableContent>

@property (nonatomic, strong, readonly) TMCodeIndex *index;

- (id)initWithIndex:(TMCodeIndex *)index fileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax;

@end
