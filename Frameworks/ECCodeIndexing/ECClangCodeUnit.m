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
#import "ClangHelperFunctions.h"
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>

@interface ECClangCodeUnit ()
{
    CXIndex _clangIndex;
    CXTranslationUnit _clangUnit;
    CXFile _clangFile;
}
- (NSArray *)_tokensInRange:(NSRange)range annotated:(BOOL)annotated;
@end

@implementation ECClangCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index clangIndex:(CXIndex)clangIndex fileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer scope:(NSString *)scope
{
    ECASSERT(index && clangIndex && fileBuffer && [scope length]);
    self = [super initWithIndex:index fileBuffer:fileBuffer scope:scope];
    if (!self)
        return nil;
    _clangIndex = clangIndex;
    int parameter_count = 11;
    const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/3.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
    const char * clangFilePath = [[[fileBuffer fileURL] path] fileSystemRepresentation];
    _clangUnit = clang_parseTranslationUnit(clangIndex, clangFilePath, parameters, parameter_count, 0, 0, clang_defaultEditingTranslationUnitOptions());
    _clangFile = clang_getFile(_clangUnit, clangFilePath);
    return self;
}

- (id<ECCodeCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return [[ECClangCodeCompletionResultSet alloc] initWithCodeUnit:self atOffset:offset];
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

- (CXTranslationUnit)clangTranslationUnit
{
    return _clangUnit;
}

@end
