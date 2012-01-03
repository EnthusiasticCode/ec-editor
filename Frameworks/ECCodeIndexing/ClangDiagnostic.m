//
//  ECClangCodeDiagnostic.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangDiagnostic.h"
#import "ClangHelperFunctions.h"

@interface ClangDiagnostic ()
{
    enum CXDiagnosticSeverity _severity;
    NSString *_spelling;
    NSUInteger _line;
    NSRange _range;
}
@end

@implementation ClangDiagnostic

- (id)initWithClangDiagnostic:(CXDiagnostic)clangDiagnostic
{
    self = [super init];
    if (!self)
        return nil;
    _severity = clang_getDiagnosticSeverity(clangDiagnostic);
    CXString clangSpelling = clang_getDiagnosticSpelling(clangDiagnostic);
    _spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    clang_getInstantiationLocation(clang_getDiagnosticLocation(clangDiagnostic), NULL, &_line, NULL, NULL);
    ECASSERT(clang_getDiagnosticNumRanges(clangDiagnostic) > 0);
    _range = Clang_SourceRangeRange(clang_getDiagnosticRange(clangDiagnostic, 0), nil);
    return self;
}

- (enum CXDiagnosticSeverity)severity
{
    return _severity;
}

- (NSString *)spelling
{
    return _spelling;
}

- (NSUInteger)line
{
    return _line;
}

- (NSRange)range
{
    return _range;
}

@end
