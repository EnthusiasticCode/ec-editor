//
//  ECClangTranslationUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangCodeUnit.h"
#import "../ECSourceLocation.h"
#import "../ECSourceRange.h"
#import "../ECToken.h"
#import "../ECFixIt.h"
#import "../ECDiagnostic.h"
#import "../ECCompletionResult.h"
#import "../ECCompletionString.h"
#import "../ECCompletionChunk.h"

const NSString *ECClangCodeUnitOptionLanguage = @"Language";

@interface ECClangCodeUnit ()
@property (nonatomic) CXTranslationUnit translationUnit;
@property (nonatomic) CXFile source;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *language;
@end

#pragma mark -
#pragma mark Private functions

static ECSourceLocation *sourceLocationFromClangSourceLocation(CXSourceLocation clangSourceLocation)
{
    CXFile clangFile;
    unsigned clangLine;
    unsigned clangColumn;
    unsigned clangOffset;
    clang_getInstantiationLocation(clangSourceLocation, &clangFile, &clangLine, &clangColumn, &clangOffset);
    CXString clangFilePath = clang_getFileName(clangFile);
    NSString *file = nil;
    if (clang_getCString(clangFilePath))
        file = [NSString stringWithUTF8String:clang_getCString(clangFilePath)];
    clang_disposeString(clangFilePath);
    return [ECSourceLocation locationWithFile:file line:clangLine column:clangColumn offset:clangOffset];
}

static ECSourceRange *sourceRangeFromClangSourceRange(CXSourceRange clangSourceRange)
{
    ECSourceLocation *start = sourceLocationFromClangSourceLocation(clang_getRangeStart(clangSourceRange));
    ECSourceLocation *end = sourceLocationFromClangSourceLocation(clang_getRangeEnd(clangSourceRange));
    return [ECSourceRange rangeWithStart:start end:end];
}

static ECToken *tokenFromClangToken(CXTranslationUnit translationUnit, CXToken clangToken)
{
    ECTokenKind kind;
    switch (clang_getTokenKind(clangToken))
    {
        case CXToken_Punctuation:
            kind = ECTokenKindPunctuation;
            break;
        case CXToken_Keyword:
            kind = ECTokenKindKeyword;
            break;
        case CXToken_Identifier:
            kind = ECTokenKindIdentifier;
            break;
        case CXToken_Literal:
            kind = ECTokenKindLiteral;
            break;
        case CXToken_Comment:
            kind = ECtokenKindComment;
            break;
    }
    CXString clangSpelling = clang_getTokenSpelling(translationUnit, clangToken);
    NSString *spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    ECSourceLocation *location = sourceLocationFromClangSourceLocation(clang_getTokenLocation(translationUnit, clangToken));
    ECSourceRange *extent = sourceRangeFromClangSourceRange(clang_getTokenExtent(translationUnit, clangToken));
    return [ECToken tokenWithKind:kind spelling:spelling location:location extent:extent];
}

static ECFixIt *fixItFromClangDiagnostic(CXDiagnostic clangDiagnostic, unsigned index)
{
    CXSourceRange clangReplacementRange;
    CXString clangString = clang_getDiagnosticFixIt(clangDiagnostic, index, &clangReplacementRange);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    ECSourceRange *replacementRange = sourceRangeFromClangSourceRange(clangReplacementRange);
    return [ECFixIt fixItWithString:string replacementRange:replacementRange];
}

static ECDiagnostic *diagnosticFromClangDiagnostic(CXDiagnostic clangDiagnostic)
{
    ECDiagnosticSeverity severity;
    switch (clang_getDiagnosticSeverity(clangDiagnostic))
    {
        case CXDiagnostic_Ignored:
            severity = ECDiagnosticSeverityIgnored;
            break;
        case CXDiagnostic_Note:
            severity = ECDiagnosticSeverityNote;
            break;
        case CXDiagnostic_Warning:
            severity = ECDiagnosticSeverityWarning;
            break;
        case CXDiagnostic_Error:
            severity = ECDiagnosticSeverityError;
            break;
        case CXDiagnostic_Fatal:
            severity = ECDiagnosticSeverityFatal;
            break;
    };
    ECSourceLocation *location = sourceLocationFromClangSourceLocation(clang_getDiagnosticLocation(clangDiagnostic));
    CXString clangSpelling = clang_getDiagnosticSpelling(clangDiagnostic);
    NSString *spelling = [NSString stringWithUTF8String:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    CXString clangCategory = clang_getDiagnosticCategoryName(clang_getDiagnosticCategory(clangDiagnostic));
    NSString *category = [NSString stringWithUTF8String:clang_getCString(clangCategory)];
    clang_disposeString(clangCategory);
    unsigned numSourceRanges = clang_getDiagnosticNumRanges(clangDiagnostic);
    NSMutableArray *sourceRanges = [NSMutableArray arrayWithCapacity:numSourceRanges];
    for (unsigned i = 0; i < numSourceRanges; i++)
        [sourceRanges addObject:sourceRangeFromClangSourceRange(clang_getDiagnosticRange(clangDiagnostic, i))];
    unsigned numFixIts = clang_getDiagnosticNumFixIts(clangDiagnostic);
    NSMutableArray *fixIts = [NSMutableArray arrayWithCapacity:numFixIts];
    for (unsigned i = 0; i < numFixIts; i++)
        [fixIts addObject:fixItFromClangDiagnostic(clangDiagnostic, i)];
    
    return [ECDiagnostic diagnosticWithSeverity:severity location:location spelling:spelling category:category sourceRanges:sourceRanges fixIts:fixIts];
}

static ECCompletionChunk *chunkFromClangCompletionString(CXCompletionString clangCompletionString, unsigned index)
{
    CXString clangString = clang_getCompletionChunkText(clangCompletionString, index);
    NSString *string = [NSString stringWithUTF8String:clang_getCString(clangString)];
    clang_disposeString(clangString);
    return [ECCompletionChunk chunkWithKind:clang_getCompletionChunkKind(clangCompletionString, index) string:string];
}

static ECCompletionString *completionStringFromClangCompletionString(CXCompletionString clangCompletionString)
{
    unsigned numChunks = clang_getNumCompletionChunks(clangCompletionString);
    NSMutableArray *chunks = [NSMutableArray arrayWithCapacity:numChunks];
    for (unsigned i = 0; i < numChunks; i++)
        [chunks addObject:chunkFromClangCompletionString(clangCompletionString, i)];
    return [ECCompletionString stringWithCompletionChunks:chunks];
}

static ECCompletionResult *completionResultFromClangCompletionResult(CXCompletionResult clangCompletionResult)
{
    ECCompletionString *completionString = completionStringFromClangCompletionString(clangCompletionResult.CompletionString);
    return [ECCompletionResult resultWithCursorKind:clangCompletionResult.CursorKind completionString:completionString];
}

@implementation ECClangCodeUnit

@synthesize translationUnit = _translationUnit;
@synthesize source = _source;
@synthesize url = _url;
@synthesize language = _language;

- (void)dealloc {
    clang_disposeTranslationUnit(self.translationUnit);
    [super dealloc];
}

- (id)initWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options
{
    self = [super init];
    if (!self)
        return nil;
    int parameter_count = 10;
    const char *filePath = [[fileURL path] fileSystemRepresentation];
    const char const *parameters[] = {"-ObjC", "-nostdinc", "-nobuiltininc", "-I/Xcode4//usr/lib/clang/2.0/include", "-I/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/usr/include", "-F/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/System/Library/Frameworks", "-isysroot=/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.2"};
    self.translationUnit = clang_parseTranslationUnit(index, filePath, parameters, parameter_count, 0, 0, CXTranslationUnit_PrecompiledPreamble | CXTranslationUnit_CacheCompletionResults);
    self.source = clang_getFile(self.translationUnit, [[fileURL path] UTF8String]);
    self.url = fileURL;
    self.language = [options objectForKey:ECClangCodeUnitOptionLanguage];
    return self;
}

+ (id)unitWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options
{
    id translationUnit = [self alloc];
    translationUnit = [translationUnit initWithFile:fileURL index:index options:options];
    return [translationUnit autorelease];
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
        ECDiagnostic *diagnostic = diagnosticFromClangDiagnostic(clangDiagnostic);
        [diagnostics addObject:diagnostic];
        clang_disposeDiagnostic(clangDiagnostic);
    }
    return diagnostics;
}

- (NSArray *)fixIts
{
    return nil;
}

- (NSArray *)tokensInRange:(NSRange)range
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
    for (unsigned i = 0; i < numTokens; i++)
    {
        [tokens addObject:tokenFromClangToken(self.translationUnit, clangTokens[i])];
    }
    clang_disposeTokens(self.translationUnit, clangTokens, numTokens);
    return tokens;
}

- (NSArray *)tokens
{
    NSUInteger fileLength = [[NSString stringWithContentsOfURL:self.url encoding:NSUTF8StringEncoding error:NULL] length];
    return [self tokensInRange:NSMakeRange(0, fileLength)];
}

@end
