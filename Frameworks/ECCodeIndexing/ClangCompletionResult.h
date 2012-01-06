//
//  ClangCompletionResult.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit.h"

@interface ClangCompletionResult : NSObject <TMCompletionResult>

- (id)initWithClangCompletionResult:(CXCompletionResult)clangCompletionResult;

@end
