//
//  ECClangCodeCursor.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCursor.h"
#import <clang-c/Index.h>

@interface ECClangCodeCursor : ECCodeCursor

- (id)initWithCXCursor:(CXCursor)clangCursor;

+ (id)cursorWithCXCursor:(CXCursor)clangCursor;

@end
