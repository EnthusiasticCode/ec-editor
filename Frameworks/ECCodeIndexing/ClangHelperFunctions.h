//
//  ClangHelperFunctions.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <clang-c/Index.h>

extern NSUInteger Clang_SourceLocationOffset(CXSourceLocation clangSourceLocation, NSURL **fileURL);
extern NSRange Clang_SourceRangeRange(CXSourceRange clangSourceRange, NSURL **fileURL);
extern NSString *Clang_CursorKindScopeIdentifier(enum CXCursorKind cursorKind);
extern NSCharacterSet *Clang_ValidCompletionTypedTextCharacterSet(void);
