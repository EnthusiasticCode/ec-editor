//
//  ECClangTranslationUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <clang-c/Index.h>
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
@property (nonatomic, retain) NSString *file;
@property (nonatomic, retain) NSString *language;
@end

#pragma mark -
#pragma mark Private functions

static void offsetAndFileFromClangSourceLocation(CXSourceLocation clangSourceLocation, NSUInteger *offset, NSString **file)
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
        *file = [NSString stringWithUTF8String:clang_getCString(clangFileName)];
    clang_disposeString(clangFileName);
}

static void rangeAndFileFromClangSourceRange(CXSourceRange clangSourceRange, NSRange *range, NSString **file)
{
    NSUInteger start = NSNotFound;
    NSString *startFile = nil;
    NSUInteger end = NSNotFound;
    offsetAndFileFromClangSourceLocation(clang_getRangeStart(clangSourceRange), &start, &startFile);
    offsetAndFileFromClangSourceLocation(clang_getRangeEnd(clangSourceRange), &end, NULL);
    if (range)
        *range = NSMakeRange(start, end - start);
    if (file)
        *file = startFile;
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
    enum CXCursorKind clangKind = clang_getCursorKind(clangCursor);
    ECCodeCursorKind kind = (ECCodeCursorKind)clangKind;
    NSString *spelling;
    CXString clangSpelling = clang_getCursorSpelling(clangCursor);
    spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    NSString *file;
    NSUInteger offset;
    CXSourceLocation clangLocation = clang_getCursorLocation(clangCursor);
    offsetAndFileFromClangSourceLocation(clangLocation, &offset, &file);
    NSRange extent;
    CXSourceRange clangExtent = clang_getCursorExtent(clangCursor);
    rangeAndFileFromClangSourceRange(clangExtent, &extent, NULL);
    NSString *unifiedSymbolResolution;
    CXString clangUSR = clang_getCursorUSR(clangCursor);
    unifiedSymbolResolution = [NSString stringWithUTF8String:clang_getCString(clangUSR)];
    clang_disposeString(clangUSR);
    return [ECCodeCursor cursorWithLanguage:language kind:kind spelling:spelling file:file offset:offset extent:extent unifiedSymbolResolution:unifiedSymbolResolution];
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
    NSString *file;
    offsetAndFileFromClangSourceLocation(clang_getTokenLocation(translationUnit, clangToken), &offset, &file);
    NSRange extent;
    rangeAndFileFromClangSourceRange(clang_getTokenExtent(translationUnit, clangToken), &extent, NULL);
    ECCodeCursor *cursor = nil;
    if (attachCursor)
        cursor = cursorFromClangCursor(clangTokenCursor);
    return [ECCodeToken tokenWithKind:kind spelling:spelling file:file offset:offset extent:extent cursor:cursor];
}

static ECCodeFixIt *fixItFromClangDiagnostic(CXDiagnostic clangDiagnostic, unsigned index)
{
    CXSourceRange clangReplacementRange;
    CXString clangString = clang_getDiagnosticFixIt(clangDiagnostic, index, &clangReplacementRange);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    NSRange replacementRange;
    NSString *file;
    rangeAndFileFromClangSourceRange(clangReplacementRange, &replacementRange, &file);
    return [ECCodeFixIt fixItWithString:string file:file replacementRange:replacementRange];
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
    NSString *file;
    offsetAndFileFromClangSourceLocation(clang_getDiagnosticLocation(clangDiagnostic), &offset, &file);
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
        rangeAndFileFromClangSourceRange(clang_getDiagnosticRange(clangDiagnostic, i), &range, NULL);
        [ranges addObject:[NSValue valueWithRange:range]];
    }
    unsigned numFixIts = clang_getDiagnosticNumFixIts(clangDiagnostic);
    NSMutableArray *fixIts = [NSMutableArray arrayWithCapacity:numFixIts];
    for (unsigned i = 0; i < numFixIts; ++i)
        [fixIts addObject:fixItFromClangDiagnostic(clangDiagnostic, i)];
    
    return [ECCodeDiagnostic diagnosticWithSeverity:severity file:file offset:offset spelling:spelling category:category sourceRanges:ranges fixIts:fixIts];
}

static ECCodeCompletionChunk *chunkFromClangCompletionString(CXCompletionString clangCompletionString, unsigned index)
{
    CXString clangString = clang_getCompletionChunkText(clangCompletionString, index);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    return [ECCodeCompletionChunk chunkWithKind:(ECCodeCompletionChunkKind)clang_getCompletionChunkKind(clangCompletionString, index) string:string];
}

static ECCodeCompletionString *completionStringFromClangCompletionString(CXCompletionString clangCompletionString)
{
    unsigned numChunks = clang_getNumCompletionChunks(clangCompletionString);
    NSMutableArray *chunks = [NSMutableArray arrayWithCapacity:numChunks];
    for (unsigned i = 0; i < numChunks; ++i)
        [chunks addObject:chunkFromClangCompletionString(clangCompletionString, i)];
    return [ECCodeCompletionString stringWithCompletionChunks:chunks];
}

static ECCodeCompletionResult *completionResultFromClangCompletionResult(CXCompletionResult clangCompletionResult)
{
    ECCodeCompletionString *completionString = completionStringFromClangCompletionString(clangCompletionResult.CompletionString);
    return [ECCodeCompletionResult resultWithCursorKind:(ECCodeCursorKind)clangCompletionResult.CursorKind completionString:completionString];
}

@implementation ECClangCodeUnit

@synthesize index = index_;
@synthesize translationUnit = translationUnit_;
@synthesize source = source_;
@synthesize file = file_;
@synthesize language = language_;

- (void)dealloc {
    clang_disposeTranslationUnit(self.translationUnit);
    self.file = nil;
    [super dealloc];
}

- (id)initWithFile:(NSString *)file index:(CXIndex)index language:(NSString *)language
{
    self = [super init];
    if (!self)
        return nil;
    if (!index)
    {
        [self release];
        return nil;
    }
    int parameter_count = 11;
    const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/2.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.3.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.3.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.3.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
    self.index = index;
    self.translationUnit = clang_parseTranslationUnit(index, [file fileSystemRepresentation], parameters, parameter_count, 0, 0, CXTranslationUnit_PrecompiledPreamble | CXTranslationUnit_CacheCompletionResults);
    self.source = clang_getFile(self.translationUnit, [file fileSystemRepresentation]);
    self.file = file;
    return self;
}

+ (id)unitForFile:(NSString *)file index:(CXIndex)index language:(NSString *)language
{
    id codeUnit = [self alloc];
    codeUnit = [codeUnit initWithFile:file index:index language:language];
    return [codeUnit autorelease];
}

- (BOOL)isDependentOnFile:(NSString *)file
{
    CXFile *clangFile = clang_getFile(self.translationUnit, [file fileSystemRepresentation]);
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
    CXCodeCompleteResults *clangCompletions = clang_codeCompleteAt(self.translationUnit, [self.file fileSystemRepresentation], line, column, NULL, 0, clang_defaultCodeCompleteOptions());
    NSMutableArray *completions = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < clangCompletions->NumResults; ++i)
        [completions addObject:completionResultFromClangCompletionResult(clangCompletions->Results[i])];
    clang_disposeCodeCompleteResults(clangCompletions);
    return [completions autorelease];
}

- (NSArray *)diagnostics
{
    if (!self.translationUnit)
        return nil;
    unsigned numDiagnostics = clang_getNumDiagnostics(self.translationUnit);
    NSMutableArray *diagnostics = [NSMutableArray arrayWithCapacity:numDiagnostics];
    for (unsigned i = 0; i < numDiagnostics; ++i)
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
    for (unsigned i = 0; i < numTokens; ++i)
    {
        [tokens addObject:tokenFromClangToken(self.translationUnit, clangTokens[i], attachCursors, clangTokenCursors[i])];
    }
    clang_disposeTokens(self.translationUnit, clangTokens, numTokens);
    free(clangTokenCursors);
    return tokens;
}

- (NSArray *)tokensWithCursors:(BOOL)attachCursors
{
    NSUInteger fileLength = [[NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:NULL] length];
    return [self tokensInRange:NSMakeRange(0, fileLength) withCursors:attachCursors];
}

@end
