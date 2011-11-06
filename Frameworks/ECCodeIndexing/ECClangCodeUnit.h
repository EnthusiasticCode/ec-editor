//
//  ECClangCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"

@interface ECClangCodeUnit : ECCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index clangIndex:(void *)clangIndex fileURL:(NSURL *)fileURL scope:(NSString *)scope;

@end
