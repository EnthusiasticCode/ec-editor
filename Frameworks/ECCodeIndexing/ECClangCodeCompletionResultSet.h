//
//  ECClangCodeCompletionResultSet.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeIndex.h"

@interface ECClangCodeCompletionResultSet : NSObject <ECCodeCompletionResultSet>

- (id)initWithCodeUnit:(ECCodeUnit *)codeUnit atOffset:(NSUInteger)offset;

@end
