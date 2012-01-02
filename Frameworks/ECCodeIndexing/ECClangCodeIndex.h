//
//  ECClangCodeIndex.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex+Internal.h"
#import <clang-c/Index.h>

extern NSString * const ClangExtensionKey;

@interface ECClangCodeIndex : NSObject <ECCodeIndexExtension>

- (CXIndex)clangIndex;

@end
