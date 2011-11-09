//
//  ECClangCodeCompletionResultSet.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"
@class ECClangCodeUnit;

@interface ECClangCodeCompletionResultSet : NSObject <ECCodeCompletionResultSet>

- (id)initWithCodeUnit:(ECClangCodeUnit *)codeUnit atOffset:(NSUInteger)offset;

@end
