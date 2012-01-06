//
//  ClangCompletionResult.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangCompletionResult.h"
#import "ClangCompletionString.h"
#import "ClangHelperFunctions.h"

@interface ClangCompletionResult ()
{
    ClangCompletionString *_completionString;
    enum CXCursorKind _cursorKind;
}
@end

@implementation ClangCompletionResult

- (id)initWithClangCompletionResult:(CXCompletionResult)clangCompletionResult
{
    self = [super init];
    if (!self)
        return nil;
    _completionString = [[ClangCompletionString alloc] initWithClangCompletionString:clangCompletionResult.CompletionString];
    _cursorKind = clangCompletionResult.CursorKind;
    return self;
}

- (id<TMCompletionString>)completionString
{
    return _completionString;
}

- (enum CXCursorKind)cursorKind
{
    return _cursorKind;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"ClangCompletionResult %@ : %@", Clang_CursorKindScopeIdentifier(_cursorKind), [_completionString description]];
}

@end
