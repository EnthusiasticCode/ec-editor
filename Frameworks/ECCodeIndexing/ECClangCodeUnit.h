//
//  ECClangCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"

@interface ECClangCodeUnit : ECCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index clangIndex:(CXIndex)clangIndex fileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer scope:(NSString *)scope;
- (CXTranslationUnit)clangTranslationUnit;

@end
