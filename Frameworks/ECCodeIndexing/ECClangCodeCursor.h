//
//  ECClangCodeCursor.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"
#import <clang-c/Index.h>

@interface ECClangCodeCursor : NSObject <ECCodeCursor>

- (id)initWithClangCursor:(CXCursor)clangCursor;

- (enum CXCursorKind)kind;

- (CXType)type;

- (ECClangCodeCursor *)semanticParent;

- (NSString *)scopeIdentifier;

@end
