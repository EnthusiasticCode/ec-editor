//
//  ECClangCodeCompletionResult.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeIndex.h"

@interface ECClangCodeCompletionResult : NSObject <ECCodeCompletionResult>

- (id)initWithClangCompletionResult:(CXCompletionResult)clangCompletionResult;

@end
