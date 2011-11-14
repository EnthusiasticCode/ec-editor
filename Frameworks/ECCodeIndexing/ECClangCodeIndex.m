//
//  ECClangCodeIndex.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex+Subclass.h"
#import "ECClangCodeIndex.h"
#import "ECClangCodeUnit.h"
#import <clang-c/Index.h>

@interface ECClangCodeIndex ()
{
    CXIndex _clangIndex;
}
@end

@implementation ECClangCodeIndex

+ (void)load
{
    [ECCodeIndex registerExtension:self];
}

- (float)supportForScope:(NSString *)scope
{
    if (![scope isEqualToString:@"source.c"] && ![scope isEqualToString:@"source.objc"] && ![scope isEqualToString:@"source.objc++"] && ![scope isEqualToString:@"source.c++"])
        return 0.0;
    return 0.8;
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

- (ECCodeUnit *)codeUnitWithIndex:(ECCodeIndex *)index forFileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer scope:(NSString *)scope
{
    ECASSERT(index && fileBuffer && scope);
    return [[ECClangCodeUnit alloc] initWithIndex:index clangIndex:_clangIndex fileBuffer:fileBuffer scope:scope];
}

@end
