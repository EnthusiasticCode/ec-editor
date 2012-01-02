//
//  ECClangCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeIndex.h"

@interface ECClangCodeUnit : NSObject <ECCodeUnitExtension>

- (CXTranslationUnit)clangTranslationUnit;

@end
