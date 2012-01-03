//
//  ECClangCodeIndex.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangIndexExtension.h"

NSString * const ClangExtensionKey = @"libclang";

@interface ClangIndexExtension ()
{
    CXIndex _clangIndex;
}
@end

@implementation ClangIndexExtension

+ (void)load
{
    [TMIndex registerExtension:self forKey:ClangExtensionKey];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _clangIndex = clang_createIndex(0, 0);
    return self;
}

- (void)dealloc
{
    clang_disposeIndex(_clangIndex);
}

- (CXIndex)clangIndex
{
    return _clangIndex;
}

@end
