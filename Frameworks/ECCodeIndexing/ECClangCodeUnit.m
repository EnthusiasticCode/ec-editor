//
//  ECClangCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeUnit.h"
#import "ECCodeUnit+Subclass.h"
#import "ECCodeIndex+Subclass.h"
#import "ECClangCodeToken.h"
#import "ECClangCodeCompletionResultSet.h"
#import "ECClangCodeDiagnostic.h"
#import "ClangHelperFunctions.h"
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>

@interface ECClangCodeUnit ()
{
    CXIndex _clangIndex;
    CXTranslationUnit _clangUnit;
    CXFile _clangFile;
    BOOL _fileBufferHasUnparsedChanges;
    id _fileBufferObserver;
}
- (NSArray *)_tokensInRange:(NSRange)range annotated:(BOOL)annotated;
- (void)_reparse;
@end

@implementation ECClangCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index clangIndex:(CXIndex)clangIndex fileBuffer:(ECFileBuffer *)fileBuffer scope:(NSString *)scope
{
    ECASSERT(index && clangIndex && fileBuffer && [scope length]);
    self = [super initWithIndex:index fileBuffer:fileBuffer scope:scope];
    if (!self)
        return nil;
    _fileBufferObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ECFileBufferDidReplaceCharactersNotificationName object:fileBuffer queue:nil usingBlock:^(NSNotification *note) {
        _fileBufferHasUnparsedChanges = YES;
    }];
    _clangIndex = clangIndex;
    [self _reparse];
    return self;
}

- (CXTranslationUnit)clangTranslationUnit
{
    return _clangUnit;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_fileBufferObserver];
}

- (id<ECCodeCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return [[ECClangCodeCompletionResultSet alloc] initWithCodeUnit:self atOffset:offset];
}

- (NSArray *)diagnostics
{
    NSMutableArray *diagnostics = [NSMutableArray array];
    NSUInteger numDiagnostics = clang_getNumDiagnostics(_clangUnit);
    for (NSUInteger diagnosticIndex = 0; diagnosticIndex < numDiagnostics; ++diagnosticIndex)
        [diagnostics addObject:[[ECClangCodeDiagnostic alloc] initWithClangDiagnostic:clang_getDiagnostic(_clangUnit, diagnosticIndex)]];
    return diagnostics;
}

- (NSArray *)tokensInRange:(NSRange)range
{
    return [self _tokensInRange:range annotated:NO];
}

- (NSArray *)annotatedTokensInRange:(NSRange)range
{
    return [self _tokensInRange:range annotated:YES];
}

- (NSArray *)_tokensInRange:(NSRange)range annotated:(BOOL)annotated
{
    if (_fileBufferHasUnparsedChanges)
        [self _reparse];
    CXToken *clangTokens;
    unsigned int numClangTokens;
    CXSourceLocation begin = clang_getLocationForOffset(_clangUnit, _clangFile, range.location);
    CXSourceLocation end = clang_getLocationForOffset(_clangUnit, _clangFile, range.location + range.length);
    clang_tokenize(_clangUnit, clang_getRange(begin, end), &clangTokens, &numClangTokens);
    if (!numClangTokens)
        return nil;
    NSMutableArray *tokens = [NSMutableArray arrayWithCapacity:numClangTokens];
    if (annotated)
    {
        CXCursor *clangCursors = malloc(numClangTokens * sizeof(CXCursor));
        clang_annotateTokens(_clangUnit, clangTokens, numClangTokens, clangCursors);
        for (unsigned int tokenIndex = 0; tokenIndex < numClangTokens; ++tokenIndex)
        {
            NSRange tokenRange = Clang_SourceRangeRange(clang_getTokenExtent(_clangUnit, clangTokens[tokenIndex]), NULL);
            __block CXCursor moreSpecificCursor = clangCursors[tokenIndex];
            if (!clang_equalCursors(clangCursors[tokenIndex], clang_getNullCursor()) && !clang_isInvalid(clang_getCursorKind(clangCursors[tokenIndex])))
                clang_visitChildrenWithBlock(clangCursors[tokenIndex], ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
                    NSRange cursorRange = Clang_SourceRangeRange(clang_getCursorExtent(cursor), NULL);
                    if (cursorRange.location > tokenRange.location || NSMaxRange(cursorRange) < NSMaxRange(tokenRange))
                        return CXChildVisit_Continue;
                    moreSpecificCursor = cursor;
                    return CXChildVisit_Recurse;
                });
            [tokens addObject:[[ECClangCodeToken alloc] initWithClangToken:clangTokens[tokenIndex] withClangTranslationUnit:_clangUnit clangCursor:moreSpecificCursor]];
        }
        free(clangCursors);
    }
    else
        for (unsigned int tokenIndex = 0; tokenIndex < numClangTokens; ++tokenIndex)
            [tokens addObject:[[ECClangCodeToken alloc] initWithClangToken:clangTokens[tokenIndex] withClangTranslationUnit:_clangUnit]];
    clang_disposeTokens(_clangUnit, clangTokens, numClangTokens);
    return tokens;
}

- (void)_reparse
{
    // TODO: reparse does not work at the moment, try again in a while after updating clang
//    clang_reparseTranslationUnit(_clangUnit, 1, &clangFileBuffer, clang_defaultReparseOptions(_clangUnit));
    clang_disposeTranslationUnit(_clangUnit);
    int parameter_count = 11;
    const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/3.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
    const char * clangFilePath = [[[[self fileBuffer] fileURL] path] fileSystemRepresentation];
    NSString *contents = [[self fileBuffer] stringInRange:NSMakeRange(0, [[self fileBuffer] length])];
    struct CXUnsavedFile clangFileBuffer = {[[[[self fileBuffer] fileURL] path] fileSystemRepresentation], [contents UTF8String], [contents length]};
    _clangUnit = clang_parseTranslationUnit(_clangIndex, clangFilePath, parameters, parameter_count, &clangFileBuffer, 1, clang_defaultEditingTranslationUnitOptions());
    _clangFile = clang_getFile(_clangUnit, clangFilePath);
}

@end
