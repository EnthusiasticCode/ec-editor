//
//  ECClangHelperFunctions.c
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangHelperFunctions.h"

#import "ECClangCodeCursor.h"

#import "ECCodeToken.h"
#import "ECCodeCompletionString.h"
#import "ECCodeCompletionResult.h"
#import "ECCodeCompletionChunk.h"
#import "ECCodeDiagnostic.h"
#import "ECCodeFixIt.h"

void ECCodeOffsetAndFileFromClangSourceLocation(CXSourceLocation clangSourceLocation, NSUInteger *offset, NSString **file)
{
    if (clang_equalLocations(clangSourceLocation, clang_getNullLocation()))
        return;
    CXFile clangFile;
    unsigned clangLine;
    unsigned clangColumn;
    unsigned clangOffset;
    clang_getInstantiationLocation(clangSourceLocation, &clangFile, &clangLine, &clangColumn, &clangOffset);
    CXString clangFileName = clang_getFileName(clangFile);
    if (offset)
        *offset = clangOffset;
    if (file)
    {
        if (clang_getCString(clangFileName))
            *file = [NSString stringWithUTF8String:clang_getCString(clangFileName)];
        else
            *file = nil;
    }
    clang_disposeString(clangFileName);
}

void ECCodeRangeAndFileFromClangSourceRange(CXSourceRange clangSourceRange, NSRange *range, NSString **file)
{
    NSUInteger start = NSNotFound;
    NSString *startFile = nil;
    NSUInteger end = NSNotFound;
    ECCodeOffsetAndFileFromClangSourceLocation(clang_getRangeStart(clangSourceRange), &start, &startFile);
    ECCodeOffsetAndFileFromClangSourceLocation(clang_getRangeEnd(clangSourceRange), &end, NULL);
    if (range)
        *range = NSMakeRange(start, end - start);
    if (file)
        *file = startFile;
}

ECCodeToken *ECCodeTokenFromClangToken(CXTranslationUnit translationUnit, CXToken clangToken, BOOL attachCursor, CXCursor clangTokenCursor)
{
    ECCodeTokenKind kind;
    switch (clang_getTokenKind(clangToken))
    {
        case CXToken_Punctuation:
            kind = ECCodeTokenKindPunctuation;
            break;
        case CXToken_Keyword:
            kind = ECCodeTokenKindKeyword;
            break;
        case CXToken_Identifier:
            kind = ECCodeTokenKindIdentifier;
            break;
        case CXToken_Literal:
            kind = ECCodeTokenKindLiteral;
            break;
        case CXToken_Comment:
            kind = ECCodeTokenKindComment;
            break;
    }
    CXString clangSpelling = clang_getTokenSpelling(translationUnit, clangToken);
    NSString *spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    NSUInteger offset;
    NSString *file;
    ECCodeOffsetAndFileFromClangSourceLocation(clang_getTokenLocation(translationUnit, clangToken), &offset, &file);
    NSRange extent;
    ECCodeRangeAndFileFromClangSourceRange(clang_getTokenExtent(translationUnit, clangToken), &extent, NULL);
    ECCodeCursor *cursor = nil;
    if (attachCursor)
        cursor = [ECClangCodeCursor cursorWithCXCursor:clangTokenCursor];
    return [ECCodeToken tokenWithKind:kind spelling:spelling file:file offset:offset extent:extent cursor:cursor];
}

ECCodeFixIt *ECCodeFixItFromClangDiagnostic(CXDiagnostic clangDiagnostic, unsigned index)
{
    CXSourceRange clangReplacementRange;
    CXString clangString = clang_getDiagnosticFixIt(clangDiagnostic, index, &clangReplacementRange);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    NSRange replacementRange;
    NSString *file;
    ECCodeRangeAndFileFromClangSourceRange(clangReplacementRange, &replacementRange, &file);
    return [ECCodeFixIt fixItWithString:string file:file replacementRange:replacementRange];
}

ECCodeDiagnostic *diagnosticFromClangDiagnostic(CXDiagnostic clangDiagnostic)
{
    ECCodeDiagnosticSeverity severity;
    switch (clang_getDiagnosticSeverity(clangDiagnostic))
    {
        case CXDiagnostic_Ignored:
            severity = ECCodeDiagnosticSeverityIgnored;
            break;
        case CXDiagnostic_Note:
            severity = ECCodeDiagnosticSeverityNote;
            break;
        case CXDiagnostic_Warning:
            severity = ECCodeDiagnosticSeverityWarning;
            break;
        case CXDiagnostic_Error:
            severity = ECCodeDiagnosticSeverityError;
            break;
        case CXDiagnostic_Fatal:
            severity = ECCodeDiagnosticSeverityFatal;
            break;
    };
    NSUInteger offset;
    NSString *file;
    ECCodeOffsetAndFileFromClangSourceLocation(clang_getDiagnosticLocation(clangDiagnostic), &offset, &file);
    CXString clangSpelling = clang_getDiagnosticSpelling(clangDiagnostic);
    NSString *spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    CXString clangCategory = clang_getDiagnosticCategoryName(clang_getDiagnosticCategory(clangDiagnostic));
    NSString *category = [NSString stringWithUTF8String:clang_getCString(clangCategory)];
    clang_disposeString(clangCategory);
    unsigned numRanges = clang_getDiagnosticNumRanges(clangDiagnostic);
    NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:numRanges];
    for (unsigned i = 0; i < numRanges; ++i)
    {
        NSRange range;
        ECCodeRangeAndFileFromClangSourceRange(clang_getDiagnosticRange(clangDiagnostic, i), &range, NULL);
        [ranges addObject:[NSValue valueWithRange:range]];
    }
    unsigned numFixIts = clang_getDiagnosticNumFixIts(clangDiagnostic);
    NSMutableArray *fixIts = [NSMutableArray arrayWithCapacity:numFixIts];
    for (unsigned i = 0; i < numFixIts; ++i)
        [fixIts addObject:ECCodeFixItFromClangDiagnostic(clangDiagnostic, i)];
    
    return [ECCodeDiagnostic diagnosticWithSeverity:severity file:file offset:offset spelling:spelling category:category sourceRanges:ranges fixIts:fixIts];
}

ECCodeCompletionChunk *ECCodeCompletionChunkFromClangCompletionString(CXCompletionString clangCompletionString, unsigned index)
{
    CXString clangString = clang_getCompletionChunkText(clangCompletionString, index);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    return [ECCodeCompletionChunk chunkWithKind:(ECCodeCompletionChunkKind)clang_getCompletionChunkKind(clangCompletionString, index) string:string];
}

ECCodeCompletionString *ECCodeCompletionStringFromClangCompletionString(CXCompletionString clangCompletionString)
{
    unsigned numChunks = clang_getNumCompletionChunks(clangCompletionString);
    NSMutableArray *chunks = [NSMutableArray arrayWithCapacity:numChunks];
    for (unsigned i = 0; i < numChunks; ++i)
        [chunks addObject:ECCodeCompletionChunkFromClangCompletionString(clangCompletionString, i)];
    return [ECCodeCompletionString stringWithCompletionChunks:chunks];
}

ECCodeCompletionResult *ECCodeCompletionResultFromClangCompletionResult(CXCompletionResult clangCompletionResult)
{
    ECCodeCompletionString *completionString = ECCodeCompletionStringFromClangCompletionString(clangCompletionResult.CompletionString);
    return [ECCodeCompletionResult resultWithCursorKind:(ECCodeCursorKind)clangCompletionResult.CursorKind completionString:completionString];
}
