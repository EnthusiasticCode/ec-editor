//
//  ECClangCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCursor.h"
#import <clang-c/Index.h>

@interface ECClangCodeCursor ()
{
    CXCursor cxCursor_;
}
@property (nonatomic) CXCursor cxCursor;
@end

@implementation ECClangCodeCursor

@synthesize cxCursor;

- (NSUInteger)hash
{
    return (NSUInteger)clang_hashCursor(cxCursor_);
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (![object isMemberOfClass:[self class]])
        return NO;
    CXCursor otherCXCursor = ((ECClangCodeCursor *)object).cxCursor;
    if (clang_equalCursors(cxCursor_, otherCXCursor))
        return YES;
    return NO;
}

@end
