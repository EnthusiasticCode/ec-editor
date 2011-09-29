//
//  ECClangCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import <clang-c/Index.h>

@interface ECClangCodeIndex : ECCodeIndex

@property (nonatomic) CXIndex index;

@end
