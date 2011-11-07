//
//  ECClangCodeToken.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import <clang-c/Index.h>

@interface ECClangCodeToken : NSObject <ECCodeToken>

- (id)initWithClangToken:(CXToken)clangToken withClangTranslationUnit:(CXTranslationUnit)clangTranslationUnit;
- (id)initWithClangToken:(CXToken)clangToken withClangTranslationUnit:(CXTranslationUnit)clangTranslationUnit clangCursor:(CXCursor)clangCursor;

@end
