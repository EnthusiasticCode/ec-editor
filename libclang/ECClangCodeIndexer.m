//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangCodeIndexer.h"

#import "ECSourceLocation.h"
#import "ECSourceRange.h"
#import "ECToken.h"
#import "ECFixIt.h"
#import "ECDiagnostic.h"
#import "ECCompletionResult.h"
#import "ECCompletionString.h"
#import "ECCompletionChunk.h"

#import <objc/message.h>

static CXIndex _cIndex;
static unsigned int _translationUnitCount;

@interface ECClangCodeIndexer()
@property (nonatomic) CXTranslationUnit translationUnit;
@end

static ECSourceLocation *sourceLocationFromClangSourceLocation(CXSourceLocation clangSourceLocation)
{
    CXFile clangFile;
    unsigned int clangLine;
    unsigned int clangColumn;
    unsigned int clangOffset;
    clang_getInstantiationLocation(clangSourceLocation, &clangFile, &clangLine, &clangColumn, &clangOffset);
    CXString clangFilePath = clang_getFileName(clangFile);
    NSString *file = [NSString stringWithCString:clang_getCString(clangFilePath)];
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
    NSString *spelling = [NSString stringWithCString:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    ECSourceLocation *location = sourceLocationFromClangSourceLocation(clang_getTokenLocation(translationUnit, clangToken));
    ECSourceRange *extent = sourceRangeFromClangSourceRange(clang_getTokenExtent(translationUnit, clangToken));
    return [ECToken tokenWithKind:kind spelling:spelling location:location extent:extent];
}

static ECFixIt *fixItFromClangDiagnostic(CXDiagnostic clangDiagnostic, int index)
{
    CXSourceRange clangReplacementRange;
    CXString clangString = clang_getDiagnosticFixIt(clangDiagnostic, (unsigned int)index, &clangReplacementRange);
    NSString *string = [NSString stringWithCString:clang_getCString(clangString)];
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
    NSString *spelling = [NSString stringWithCString:clang_getCString(clangSpelling)];
    clang_disposeString(clangSpelling);
    CXString clangCategory = clang_getDiagnosticCategoryName(clang_getDiagnosticCategory(clangDiagnostic));
    NSString *category = [NSString stringWithCString:clang_getCString(clangCategory)];
    clang_disposeString(clangCategory);
    int numSourceRanges = clang_getDiagnosticNumRanges(clangDiagnostic);
    NSMutableArray *sourceRanges = [NSMutableArray arrayWithCapacity:numSourceRanges];
    for (int i = 0; i < numSourceRanges; i++)
    {
        [sourceRanges addObject:sourceRangeFromClangSourceRange(clang_getDiagnosticRange(clangDiagnostic, i))];
    }
    int numFixIts = clang_getDiagnosticNumFixIts(clangDiagnostic);
    NSMutableArray *fixIts = [NSMutableArray arrayWithCapacity:numFixIts];
    for (int i = 0; i < numFixIts; i++)
    {
        [fixIts addObject:fixItFromClangDiagnostic(clangDiagnostic, i)];
    }
    
    return [ECDiagnostic diagnosticWithSeverity:severity location:location spelling:spelling category:category sourceRanges:sourceRanges fixIts:fixIts];
}

@implementation ECClangCodeIndexer

@synthesize source = _source;
@synthesize diagnostics = _diagnostics;
@synthesize translationUnit = _translationUnit;

- (void)setSource:(NSString *)source
{
    if (!_cIndex)
        _cIndex = clang_createIndex(0, 0);
    int parameter_count = 10;
    const char const *parameters[] = {"-ObjC", "-nostdinc", "-nobuiltininc", "-I/Xcode4//usr/lib/clang/2.0/include", "-I/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/usr/include", "-F/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/System/Library/Frameworks", "-isysroot=/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.2"};
    self.translationUnit = clang_parseTranslationUnit(_cIndex, [source cStringUsingEncoding:NSUTF8StringEncoding], parameters, parameter_count, 0, 0, CXTranslationUnit_PrecompiledPreamble | CXTranslationUnit_CacheCompletionResults);
    if (!self.translationUnit)
    {
        [_source release];
        _source = nil;
    }
    _translationUnitCount++;
    [_source release];
    _source = [source retain];
}

- (NSArray *)diagnostics
{
    if (_diagnostics)
        return _diagnostics;
    
    int numDiagnostics = clang_getNumDiagnostics(self.translationUnit);
    _diagnostics = [[NSMutableArray alloc] initWithCapacity:numDiagnostics];
    for (int i = 0; i < numDiagnostics; i++)
    {
        CXDiagnostic clangDiagnostic = clang_getDiagnostic(self.translationUnit, i);
        ECDiagnostic *diagnostic = diagnosticFromClangDiagnostic(clangDiagnostic);
        [_diagnostics addObject:diagnostic];
        clang_disposeDiagnostic(clangDiagnostic);
    }
    return _diagnostics;
}

- (void)dealloc
{
    if (_translationUnit)
    {
        clang_disposeTranslationUnit(_translationUnit);
        _translationUnitCount--;
    }
    if (!_translationUnitCount)
    {
        clang_disposeIndex(_cIndex);
        _cIndex = NULL;
    }
    [super dealloc];
}

- (id)init
{
    // crazy hack to send init to grandparent class instead of parent class, needed to init instances of class cluster without looping
    struct objc_super grandsuper;
    grandsuper.receiver = self;
    grandsuper.super_class = [[self superclass] superclass];
    self = objc_msgSendSuper(&grandsuper, _cmd);
    return self;
}

+ (void)initialize
{
    _cIndex = NULL;
    _translationUnitCount = 0;
}

- (NSArray *)completionsWithSelection:(NSRange)selection;
{    
//    NSRange replacementRange = [self completionRangeWithSelection:selection inString:string];
//    NSArray *guesses;
    NSMutableArray *completions = [[[NSMutableArray alloc] init] autorelease];
//    for (NSString *guess in guesses)
//    {
//        [completions addObject:[ECCompletionString stringWithCompletionChunks:[NSArray arrayWithObject:[ECCompletionChunk chunkWithKind:CXCompletionChunk_TypedText string:guess]]]];
//    }
    return completions;
}

- (NSArray *)tokensForRange:(NSRange)range
{
    if (!self.translationUnit || !self.source)
        return nil;
    if (range.location == NSNotFound)
        return nil;
    unsigned int numTokens;
    CXToken *clangTokens;
    CXFile clangFile = clang_getFile(self.translationUnit, [self.source cStringUsingEncoding:NSUTF8StringEncoding]);
    CXSourceLocation clangStart = clang_getLocationForOffset(self.translationUnit, clangFile, range.location);
    CXSourceLocation clangEnd = clang_getLocationForOffset(self.translationUnit, clangFile, range.location + range.length);
    CXSourceRange clangRange = clang_getRange(clangStart, clangEnd);
    clang_tokenize(self.translationUnit, clangRange, &clangTokens, &numTokens);
    NSMutableArray *tokens = [NSMutableArray arrayWithCapacity:numTokens];
    for (int i = 0; i < numTokens; i++)
    {
        [tokens addObject:tokenFromClangToken(self.translationUnit, clangTokens[i])];
    }
    return tokens;
}

@end
