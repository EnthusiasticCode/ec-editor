//
//  ECClangCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"
#import <clang-c/Index.h>

@interface ECClangCodeUnit : ECCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index clangIndex:(CXIndex)clangIndex fileURL:(NSURL *)fileURL scope:(NSString *)scope;

@end
