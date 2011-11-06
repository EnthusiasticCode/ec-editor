//
//  ECClangCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeUnit.h"
#import "ECCodeUnit+Subclass.h"
#import <clang-c/Index.h>

@interface ECClangCodeUnit ()
{
    CXIndex _clangIndex;
}
@end

@implementation ECClangCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index clangIndex:(void *)clangIndex fileURL:(NSURL *)fileURL scope:(NSString *)scope
{
    ECASSERT(index && clangIndex && fileURL && [scope length]);
    self = [super initWithIndex:index file:fileURL scope:scope];
    if (!self)
        return nil;
    _clangIndex = clangIndex;
    return self;
}

@end
