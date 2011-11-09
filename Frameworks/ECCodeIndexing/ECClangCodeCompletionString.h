//
//  ECClangCodeCompletionString.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"

@interface ECClangCodeCompletionString : NSObject <ECCodeCompletionString>

- (id)initWithClangCompletionString:(CXCompletionString)clangCompletionString;

@end
