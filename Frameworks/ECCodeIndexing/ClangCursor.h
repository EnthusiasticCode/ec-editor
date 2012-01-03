//
//  ECClangCodeCursor.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangIndexExtension.h"

@interface ClangCursor : NSObject <ECCodeCursor>

- (id)initWithClangCursor:(CXCursor)clangCursor;

- (enum CXCursorKind)kind;

- (CXType)type;

- (ClangCursor *)semanticParent;

- (NSString *)scopeIdentifier;

@end
