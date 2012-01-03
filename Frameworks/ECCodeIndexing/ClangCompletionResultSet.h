//
//  ClangCompletionResultSet.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangIndexExtension.h"

@interface ClangCompletionResultSet : NSObject <ECCodeCompletionResultSet>

- (id)initWithCodeUnit:(TMUnit *)codeUnit atOffset:(NSUInteger)offset;

@end
