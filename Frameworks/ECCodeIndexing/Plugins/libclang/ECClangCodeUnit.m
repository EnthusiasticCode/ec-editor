//
//  ECClangTranslationUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangCodeUnit.h"
#import "ECClangCodeIndex.h"
#import <ECCodeIndexing/ECCodeToken.h>
#import <ECCodeIndexing/ECCodeFixIt.h>
#import <ECCodeIndexing/ECCodeDiagnostic.h>
#import <ECCodeIndexing/ECCodeCompletionResult.h>
#import <ECCodeIndexing/ECCodeCompletionString.h>
#import <ECCodeIndexing/ECCodeCompletionChunk.h>
#import <ECCodeIndexing/ECCodeCursor.h>

const NSString *ECClangCodeUnitOptionLanguage = @"Language";
const NSString *ECClangCodeUnitOptionCXIndex = @"CXIndex";

@interface ECClangCodeUnit ()
@property (nonatomic) CXIndex index;
@property (nonatomic) CXTranslationUnit translationUnit;
@property (nonatomic) CXFile source;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *language;
@end

#pragma mark -
#pragma mark Private functions

static void offsetAndURLFromClangSourceLocation(CXSourceLocation clangSourceLocation, NSUInteger *offset, NSURL **url)
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
    if (url)
        *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:clang_getCString(clangFileName)]];
    clang_disposeString(clangFileName);
}

static void rangeAndURLFromClangSourceRange(CXSourceRange clangSourceRange, NSRange *range, NSURL **url)
{
    NSUInteger start = NSNotFound;
    NSURL *startURL = nil;
    NSUInteger end = NSNotFound;
    offsetAndURLFromClangSourceLocation(clang_getRangeStart(clangSourceRange), &start, &startURL);
    offsetAndURLFromClangSourceLocation(clang_getRangeEnd(clangSourceRange), &end, NULL);
    if (range)
        *range = NSMakeRange(start, end - start);
    if (url)
        *url = startURL;
}

static ECCodeCursor *cursorFromClangCursor(CXCursor clangCursor)
{
    if (clang_equalCursors(clangCursor, clang_getNullCursor()))
        return nil;
    NSString *language;
    enum CXLanguageKind clangLanguage = clang_getCursorLanguage(clangCursor);
    switch (clangLanguage)
    {
        case CXLanguage_C:
            language = @"C";
            break;
        case CXLanguage_ObjC:
            language = @"Objective C";
            break;
        case CXLanguage_CPlusPlus:
            language = @"C++";
            break;
        case CXLanguage_Invalid:
        default:
            language = @"Unknown";
    }
    ECCodeCursorKind kind = ECCodeCursorUnknown;
    enum CXCursorKind clangKind = clang_getCursorKind(clangCursor);
    if (clang_isDeclaration(clangKind))
        kind = ECCodeCursorDeclaration;
    if (clang_isExpression(clangKind))
        kind = ECCodeCursorExpression;
    if (clang_isInvalid(clangKind))
        kind = ECCodeCursorInvalid;
    if (clang_isPreprocessing(clangKind))
        kind = ECCodeCursorPreprocessing;
    if (clang_isReference(clangKind))
        kind = ECCodeCursorReference;
    if (clang_isStatement(clangKind))
        kind = ECCodeCursorStatement;
    if (clang_isTranslationUnit(clangKind))
        kind = ECCodeCursorUnit;
    if (clang_isUnexposed(clangKind))
        kind = ECCodeCursorUnexposed;
    NSString *detailedKind;
    CXString clangKindSpelling = clang_getCursorKindSpelling(clangKind);
    detailedKind = [NSString stringWithUTF8String:clang_getCString(clangKindSpelling)];
    clang_disposeString(clangKindSpelling);
    NSString *spelling;
    CXString clangSpelling = clang_getCursorSpelling(clangCursor);
    spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    NSURL *fileURL;
    NSUInteger offset;
    CXSourceLocation clangLocation = clang_getCursorLocation(clangCursor);
    offsetAndURLFromClangSourceLocation(clangLocation, &offset, &fileURL);
    NSRange extent;
    CXSourceRange clangExtent = clang_getCursorExtent(clangCursor);
    rangeAndURLFromClangSourceRange(clangExtent, &extent, NULL);
    NSString *unifiedSymbolResolution;
    CXString clangUSR = clang_getCursorUSR(clangCursor);
    unifiedSymbolResolution = [NSString stringWithUTF8String:clang_getCString(clangUSR)];
    clang_disposeString(clangUSR);
    return [ECCodeCursor cursorWithLanguage:language kind:kind detailedKind:detailedKind spelling:spelling fileURL:fileURL offset:offset extent:extent unifiedSymbolResolution:unifiedSymbolResolution];
}

static ECCodeToken *tokenFromClangToken(CXTranslationUnit translationUnit, CXToken clangToken, BOOL attachCursor, CXCursor clangTokenCursor)
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
    NSURL *fileURL;
    offsetAndURLFromClangSourceLocation(clang_getTokenLocation(translationUnit, clangToken), &offset, &fileURL);
    NSRange extent;
    rangeAndURLFromClangSourceRange(clang_getTokenExtent(translationUnit, clangToken), &extent, NULL);
    ECCodeCursor *cursor = nil;
    if (attachCursor)
        cursor = cursorFromClangCursor(clangTokenCursor);
    return [ECCodeToken tokenWithKind:kind spelling:spelling fileURL:fileURL offset:offset extent:extent cursor:cursor];
}

static ECCodeFixIt *fixItFromClangDiagnostic(CXDiagnostic clangDiagnostic, unsigned index)
{
    CXSourceRange clangReplacementRange;
    CXString clangString = clang_getDiagnosticFixIt(clangDiagnostic, index, &clangReplacementRange);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    NSRange replacementRange;
    NSURL *fileURL;
    rangeAndURLFromClangSourceRange(clangReplacementRange, &replacementRange, &fileURL);
    return [ECCodeFixIt fixItWithString:string fileURL:fileURL replacementRange:replacementRange];
}

static ECCodeDiagnostic *diagnosticFromClangDiagnostic(CXDiagnostic clangDiagnostic)
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
    NSURL *fileURL;
    offsetAndURLFromClangSourceLocation(clang_getDiagnosticLocation(clangDiagnostic), &offset, &fileURL);
    CXString clangSpelling = clang_getDiagnosticSpelling(clangDiagnostic);
    NSString *spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    CXString clangCategory = clang_getDiagnosticCategoryName(clang_getDiagnosticCategory(clangDiagnostic));
    NSString *category = [NSString stringWithUTF8String:clang_getCString(clangCategory)];
    clang_disposeString(clangCategory);
    unsigned numRanges = clang_getDiagnosticNumRanges(clangDiagnostic);
    NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:numRanges];
    for (unsigned i = 0; i < numRanges; i++)
    {
        NSRange range;
        rangeAndURLFromClangSourceRange(clang_getDiagnosticRange(clangDiagnostic, i), &range, NULL);
        [ranges addObject:[NSValue valueWithRange:range]];
    }
    unsigned numFixIts = clang_getDiagnosticNumFixIts(clangDiagnostic);
    NSMutableArray *fixIts = [NSMutableArray arrayWithCapacity:numFixIts];
    for (unsigned i = 0; i < numFixIts; i++)
        [fixIts addObject:fixItFromClangDiagnostic(clangDiagnostic, i)];
    
    return [ECCodeDiagnostic diagnosticWithSeverity:severity fileURL:fileURL offset:offset spelling:spelling category:category sourceRanges:ranges fixIts:fixIts];
}

static ECCodeCompletionChunk *chunkFromClangCompletionString(CXCompletionString clangCompletionString, unsigned index)
{
    CXString clangString = clang_getCompletionChunkText(clangCompletionString, index);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    return [ECCodeCompletionChunk chunkWithKind:clang_getCompletionChunkKind(clangCompletionString, index) string:string];
}

static ECCodeCompletionString *completionStringFromClangCompletionString(CXCompletionString clangCompletionString)
{
    unsigned numChunks = clang_getNumCompletionChunks(clangCompletionString);
    NSMutableArray *chunks = [NSMutableArray arrayWithCapacity:numChunks];
    for (unsigned i = 0; i < numChunks; i++)
        [chunks addObject:chunkFromClangCompletionString(clangCompletionString, i)];
    return [ECCodeCompletionString stringWithCompletionChunks:chunks];
}

static ECCodeCompletionResult *completionResultFromClangCompletionResult(CXCompletionResult clangCompletionResult)
{
    ECCodeCompletionString *completionString = completionStringFromClangCompletionString(clangCompletionResult.CompletionString);
    return [ECCodeCompletionResult resultWithCursorKind:clangCompletionResult.CursorKind completionString:completionString];
}

@implementation ECClangCodeUnit

@synthesize index = index_;
@synthesize translationUnit = translationUnit_;
@synthesize source = source_;
@synthesize url = url_;
@synthesize language = language_;

- (void)dealloc {
    clang_disposeTranslationUnit(self.translationUnit);
    self.url = nil;
    [super dealloc];
}

- (id)initWithFile:(NSURL *)fileURL index:(CXIndex)index language:(NSString *)language
{
    self = [super init];
    if (!self)
        return nil;
    if (!index)
    {
        [self release];
        return nil;
    }
    int parameter_count = 10;
    const char *filePath = [[fileURL path] fileSystemRepresentation];
    const char const *parameters[] = {"-ObjC", "-nostdinc", "-nobuiltininc", "-I/Xcode4//usr/lib/clang/2.0/include", "-I/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/usr/include", "-F/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/System/Library/Frameworks", "-isysroot=/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.2"};
    self.index = index;
    self.translationUnit = clang_parseTranslationUnit(index, filePath, parameters, parameter_count, 0, 0, CXTranslationUnit_PrecompiledPreamble | CXTranslationUnit_CacheCompletionResults);
    self.source = clang_getFile(self.translationUnit, [[fileURL path] UTF8String]);
    self.url = fileURL;
    return self;
}

+ (id)unitWithFile:(NSURL *)fileURL index:(CXIndex)index language:(NSString *)language
{
    id codeUnit = [self alloc];
    codeUnit = [codeUnit initWithFile:fileURL index:index language:language];
    return [codeUnit autorelease];
}

- (BOOL)isDependentOnFile:(NSURL *)fileURL
{
    CXFile *clangFile = clang_getFile(self.translationUnit, [[fileURL path] UTF8String]);
    if (clangFile)
        return YES;
    return NO;
}

- (void)reparseDependentFiles:(NSArray *)files
{
    
}

- (NSArray *)completionsWithSelection:(NSRange)selection
{
    CXSourceLocation selectionLocation = clang_getLocationForOffset(self.translationUnit, self.source, selection.location);
    unsigned line;
    unsigned column;
    clang_getInstantiationLocation(selectionLocation, NULL, &line, &column, NULL);
    CXCodeCompleteResults *clangCompletions = clang_codeCompleteAt(self.translationUnit, [[self.url path] UTF8String], line, column, NULL, 0, clang_defaultCodeCompleteOptions());
    NSMutableArray *completions = [[[NSMutableArray alloc] init] autorelease];
    for (unsigned i = 0; i < clangCompletions->NumResults; i++)
        [completions addObject:completionResultFromClangCompletionResult(clangCompletions->Results[i]).completionString];
    clang_disposeCodeCompleteResults(clangCompletions);
    return completions;
}

- (NSArray *)diagnostics
{
    if (!self.translationUnit)
        return nil;
    unsigned numDiagnostics = clang_getNumDiagnostics(self.translationUnit);
    NSMutableArray *diagnostics = [NSMutableArray arrayWithCapacity:numDiagnostics];
    for (unsigned i = 0; i < numDiagnostics; i++)
    {
        CXDiagnostic clangDiagnostic = clang_getDiagnostic(self.translationUnit, i);
        ECCodeDiagnostic *diagnostic = diagnosticFromClangDiagnostic(clangDiagnostic);
        [diagnostics addObject:diagnostic];
        clang_disposeDiagnostic(clangDiagnostic);
    }
    return diagnostics;
}

- (NSArray *)fixIts
{
    return nil;
}

- (NSArray *)tokensInRange:(NSRange)range withCursors:(BOOL)attachCursors
{
    if (!self.source)
        return nil;
    if (range.location == NSNotFound)
        return nil;
    unsigned numTokens;
    CXToken *clangTokens;
    CXSourceLocation clangStart = clang_getLocationForOffset(self.translationUnit, self.source, range.location);
    CXSourceLocation clangEnd = clang_getLocationForOffset(self.translationUnit, self.source, range.location + range.length);
    CXSourceRange clangRange = clang_getRange(clangStart, clangEnd);
    clang_tokenize(self.translationUnit, clangRange, &clangTokens, &numTokens);
    NSMutableArray *tokens = [NSMutableArray arrayWithCapacity:numTokens];
    CXCursor *clangTokenCursors = malloc(numTokens * sizeof(CXCursor));
    if (attachCursors)
        clang_annotateTokens(self.translationUnit, clangTokens, numTokens, clangTokenCursors);
    for (unsigned i = 0; i < numTokens; i++)
    {
        [tokens addObject:tokenFromClangToken(self.translationUnit, clangTokens[i], attachCursors, clangTokenCursors[i])];
    }
    clang_disposeTokens(self.translationUnit, clangTokens, numTokens);
    free(clangTokenCursors);
    return tokens;
}

- (NSArray *)tokensWithCursors:(BOOL)attachCursors
{
    NSUInteger fileLength = [[NSString stringWithContentsOfURL:self.url encoding:NSUTF8StringEncoding error:NULL] length];
    return [self tokensInRange:NSMakeRange(0, fileLength) withCursors:attachCursors];
}

@end
