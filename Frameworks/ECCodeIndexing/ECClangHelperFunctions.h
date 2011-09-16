//
//  ECClangHelperFunctions.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <clang-c/Index.h>

@class ECCodeToken, ECCodeFixIt, ECCodeDiagnostic, ECCodeCompletionChunk, ECCodeCompletionString, ECCodeCompletionResult;

void ECCodeOffsetAndFileFromClangSourceLocation(CXSourceLocation clangSourceLocation, NSUInteger *offset, NSString **file);
void ECCodeRangeAndFileFromClangSourceRange(CXSourceRange clangSourceRange, NSRange *range, NSString **file);
ECCodeToken *ECCodeTokenFromClangToken(CXTranslationUnit translationUnit, CXToken clangToken, BOOL attachCursor, CXCursor clangTokenCursor);
ECCodeFixIt *ECCodeFixItFromClangDiagnostic(CXDiagnostic clangDiagnostic, unsigned index);
ECCodeDiagnostic *diagnosticFromClangDiagnostic(CXDiagnostic clangDiagnostic);
ECCodeCompletionChunk *ECCodeCompletionChunkFromClangCompletionString(CXCompletionString clangCompletionString, unsigned index);
ECCodeCompletionString *ECCodeCompletionStringFromClangCompletionString(CXCompletionString clangCompletionString);
ECCodeCompletionResult *ECCodeCompletionResultFromClangCompletionResult(CXCompletionResult clangCompletionResult);
