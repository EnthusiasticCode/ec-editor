//
//  ECClangCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit+Internal.h"

@interface ClangUnitExtension : NSObject <TMUnitExtension>

- (CXTranslationUnit)clangTranslationUnit;

@end
