//
//  ClangIndexExtension.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexing+Internal.h"
#import <clang-c/Index.h>

extern NSString * const ClangExtensionKey;

@interface ClangIndexExtension : NSObject <TMIndexExtension>

- (CXIndex)clangIndex;

@end
