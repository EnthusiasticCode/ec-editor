//
//  ECClangCodeToken.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeToken.h"
#import "ClangHelperFunctions.h"
#import "ECClangCodeCursor.h"

@interface ECClangCodeToken ()
{
    NSRange _range;
    NSString *_spelling;
    CXTokenKind _kind;
    id<ECCodeCursor>_cursor;
}
@end

@implementation ECClangCodeToken

- (id)initWithClangToken:(CXToken)clangToken withClangTranslationUnit:(CXTranslationUnit)clangTranslationUnit
{
    self = [super init];
    if (!self)
        return nil;
    _range = Clang_SourceRangeRange(clang_getTokenExtent(clangTranslationUnit, clangToken), NULL);
    CXString clangSpelling = clang_getTokenSpelling(clangTranslationUnit, clangToken);
    _spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    _kind = clang_getTokenKind(clangToken);
    return self;
}

- (id)initWithClangToken:(CXToken)clangToken withClangTranslationUnit:(CXTranslationUnit)clangTranslationUnit clangCursor:(CXCursor)clangCursor
{
    self = [self initWithClangToken:clangToken withClangTranslationUnit:clangTranslationUnit];
    if (!self)
        return nil;
    _cursor = [[ECClangCodeCursor alloc] initWithClangCursor:clangCursor];
    return self;
}

- (NSRange)range
{
    return _range;
}

- (NSString *)spelling
{
    return _spelling;
}

- (CXTokenKind)kind
{
    return _kind;
}

- (NSString *)scopeIdentifier
{
    switch ([self kind])
    {
        case CXToken_Comment:
            return @"comment";
        case CXToken_Identifier:
            return @"variable";
        case CXToken_Keyword:
            return @"keyword";
        case CXToken_Literal:
            return @"string";
        case CXToken_Punctuation:
            return @"punctuation";
    }
}

- (NSArray *)scopeIdentifiersStack
{
    return [NSArray arrayWithObject:[self scopeIdentifier]];
}

- (id<ECCodeCursor>)cursor
{
    return _cursor;
}

@end
