//
//  ECClangCodeCompletionResult.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCompletionResult.h"
#import "ECClangCodeCompletionString.h"
#import "ClangHelperFunctions.h"

@interface ECClangCodeCompletionResult ()
{
    ECClangCodeCompletionString *_completionString;
    enum CXCursorKind _cursorKind;
}
@end

@implementation ECClangCodeCompletionResult

- (id)initWithClangCompletionResult:(CXCompletionResult)clangCompletionResult
{
    self = [super init];
    if (!self)
        return nil;
    _completionString = [[ECClangCodeCompletionString alloc] initWithClangCompletionString:clangCompletionResult.CompletionString];
    _cursorKind = clangCompletionResult.CursorKind;
    return self;
}

- (id<ECCodeCompletionString>)completionString
{
    return _completionString;
}

- (enum CXCursorKind)cursorKind
{
    return _cursorKind;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"ECClangCodeCompletionResult %@ : %@", Clang_CursorKindScopeIdentifier(_cursorKind), [_completionString description]];
}

@end
