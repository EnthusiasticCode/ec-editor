//
//  ECClangCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCursor.h"
#import <ECFoundation/ECWeakDictionary.h>
#import "ClangHelperFunctions.h"

static ECWeakDictionary *_cursorsByUSR;

@interface ECClangCodeCursor ()
{
    NSString *_USR;
    enum CXCursorKind _kind;
    CXType _type;
    ECClangCodeCursor *_semanticParent;
    NSString *_scopeIdentifier;
}
@end

@implementation ECClangCodeCursor

+ (void)initialize
{
    if (self != [ECClangCodeCursor class])
        return;
    _cursorsByUSR = [[ECWeakDictionary alloc] init];
}

- (id)initWithClangCursor:(CXCursor)clangCursor
{
    if (clang_equalCursors(clangCursor, clang_getNullCursor()))
        return nil;
    CXString clangUSR = clang_getCursorUSR(clangCursor);
    NSString *USR = [NSString stringWithUTF8String:clang_getCString(clangUSR)];
    clang_disposeString(clangUSR);
    ECClangCodeCursor *existingCursor = [_cursorsByUSR objectForKey:USR];
    if (existingCursor)
        return existingCursor;
    self = [super init];
    if (!self)
        return nil;
    _USR = USR;
    _kind = clang_getCursorKind(clangCursor);
    _type = clang_getCursorType(clangCursor);
    _semanticParent = [[ECClangCodeCursor alloc] initWithClangCursor:clang_getCursorSemanticParent(clangCursor)];
    _scopeIdentifier = Clang_CursorKindScopeIdentifier(clang_getCursorKind(clangCursor));
    [_cursorsByUSR setObject:self forKey:USR];
    return self;
}

- (enum CXCursorKind)kind
{
    return _kind;
}

- (CXType)type
{
    return _type;
}

- (ECClangCodeCursor *)semanticParent
{
    return _semanticParent;
}

- (NSString *)scopeIdentifier
{
    return _scopeIdentifier;
}

@end
