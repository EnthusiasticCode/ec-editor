//
//  ClangCompletionChunk.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit.h"

@interface ClangCompletionChunk : NSObject <TMCompletionChunk>

- (id)initWithKind:(enum CXCompletionChunkKind)kind text:(NSString *)text completionString:(id<TMCompletionString>)completionString;

@end
