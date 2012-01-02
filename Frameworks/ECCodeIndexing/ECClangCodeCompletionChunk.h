//
//  ECClangCodeCompletionChunk.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeIndex.h"

@interface ECClangCodeCompletionChunk : NSObject <ECCodeCompletionChunk>

- (id)initWithKind:(enum CXCompletionChunkKind)kind text:(NSString *)text completionString:(id<ECCodeCompletionString>)completionString;

@end
