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
- (void)reparseTranslationUnitWithUnsavedFileBuffers:(NSDictionary *)fileBuffers;
@end

#pragma mark -
#pragma mark Private functions

//static NSRange completionRange(NSString *string, NSRange selection)
//{        
//    if (!string || selection.length || !selection.location) //range of text is selected or caret is at beginning of file
//        return NSMakeRange(NSNotFound, 0);
//        
//        NSUInteger precedingCharacterIndex = selection.location - 1;
//        NSUInteger precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
//        
//        if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
//            return NSMakeRange(NSNotFound, 0);
//            
//            while (precedingCharacterIndex)
//            {
//                if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
//                {
//                    NSUInteger length = selection.location - (precedingCharacterIndex + 1);
//                    if (length)
//                        return NSMakeRange(precedingCharacterIndex + 1, length);
//                }
//                precedingCharacterIndex--;
//                precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
//            }
//    return NSMakeRange(0, selection.location); //if control has reached this point all character between the caret and the beginning of file are letters
//}

static ECSourceLocation *sourceLocationFromClangSourceLocation(CXSourceLocation clangSourceLocation)
{
    CXFile clangFile;
    unsigned int clangLine;
    unsigned int clangColumn;
    unsigned int clangOffset;
    clang_getInstantiationLocation(clangSourceLocation, &clangFile, &clangLine, &clangColumn, &clangOffset);
    CXString clangFilePath = clang_getFileName(clangFile);
    NSString *file = [NSString stringWithCString:clang_getCString(clangFilePath) encoding:NSUTF8StringEncoding];
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
    NSString *spelling = [NSString stringWithCString:clang_getCString(clangSpelling) encoding:NSUTF8StringEncoding];
    clang_disposeString(clangSpelling);
    ECSourceLocation *location = sourceLocationFromClangSourceLocation(clang_getTokenLocation(translationUnit, clangToken));
    ECSourceRange *extent = sourceRangeFromClangSourceRange(clang_getTokenExtent(translationUnit, clangToken));
    return [ECToken tokenWithKind:kind spelling:spelling location:location extent:extent];
}

static ECFixIt *fixItFromClangDiagnostic(CXDiagnostic clangDiagnostic, int index)
{
    CXSourceRange clangReplacementRange;
    CXString clangString = clang_getDiagnosticFixIt(clangDiagnostic, (unsigned int)index, &clangReplacementRange);
    NSString *string = [NSString stringWithCString:clang_getCString(clangString) encoding:NSUTF8StringEncoding];
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
    NSString *spelling = [NSString stringWithCString:clang_getCString(clangSpelling) encoding:NSUTF8StringEncoding];
    clang_disposeString(clangSpelling);
    CXString clangCategory = clang_getDiagnosticCategoryName(clang_getDiagnosticCategory(clangDiagnostic));
    NSString *category = [NSString stringWithCString:clang_getCString(clangCategory) encoding:NSUTF8StringEncoding];
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

#pragma mark -
@implementation ECClangCodeIndexer

#pragma mark Properties

@synthesize source = _source;
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

#pragma mark Initialization

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

#pragma mark -
#pragma mark Private methods

- (void)reparseTranslationUnitWithUnsavedFileBuffers:(NSDictionary *)fileBuffers
{
    if (!self.translationUnit)
        return;
    unsigned int numUnsavedFiles = [fileBuffers count];
    struct CXUnsavedFile *unsavedFiles = malloc(numUnsavedFiles * sizeof(struct CXUnsavedFile));
    int i = 0;
    for (NSString *file in [fileBuffers allKeys]) {
        unsavedFiles[i].Filename = [file cStringUsingEncoding:NSUTF8StringEncoding];
        NSString *fileBuffer = [fileBuffers objectForKey:file];
        unsavedFiles[i].Contents = [fileBuffer cStringUsingEncoding:NSUTF8StringEncoding];
        unsavedFiles[i].Length = [fileBuffer length];
        i++;
    }
    clang_reparseTranslationUnit(self.translationUnit, numUnsavedFiles, unsavedFiles, clang_defaultReparseOptions(self.translationUnit));
    free(unsavedFiles);
}

#pragma mark -
#pragma mark ECCodeIndexer

- (NSArray *)completionsForSelection:(NSRange)selection withUnsavedFileBuffers:(NSDictionary *)fileBuffers
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

- (NSArray *)diagnostics
{
    if (!self.translationUnit)
        return nil;
    int numDiagnostics = clang_getNumDiagnostics(self.translationUnit);
    NSMutableArray *diagnostics = [NSMutableArray arrayWithCapacity:numDiagnostics];
    for (int i = 0; i < numDiagnostics; i++)
    {
        CXDiagnostic clangDiagnostic = clang_getDiagnostic(self.translationUnit, i);
        ECDiagnostic *diagnostic = diagnosticFromClangDiagnostic(clangDiagnostic);
        [diagnostics addObject:diagnostic];
        clang_disposeDiagnostic(clangDiagnostic);
    }
    return diagnostics;
}

- (NSArray *)tokensForRange:(NSRange)range withUnsavedFileBuffers:(NSDictionary *)fileBuffers
{
    if (!self.translationUnit || !self.source || ![self.source length])
        return nil;
    if (range.location == NSNotFound)
        return nil;
    if (fileBuffers)
        [self reparseTranslationUnitWithUnsavedFileBuffers:fileBuffers];
    unsigned int numTokens;
    CXToken *clangTokens;
    CXFile clangFile = clang_getFile(self.translationUnit, [self.source cStringUsingEncoding:NSUTF8StringEncoding]);
    CXSourceLocation clangStart = clang_getLocationForOffset(self.translationUnit, clangFile, range.location);
    CXSourceLocation clangEnd = clang_getLocationForOffset(self.translationUnit, clangFile, range.location + range.length);
    CXSourceRange clangRange = clang_getRange(clangStart, clangEnd);
    clang_tokenize(self.translationUnit, clangRange, &clangTokens, &numTokens);
    NSMutableArray *tokens = [NSMutableArray arrayWithCapacity:numTokens];
    for (unsigned int i = 0; i < numTokens; i++)
    {
        [tokens addObject:tokenFromClangToken(self.translationUnit, clangTokens[i])];
    }
    clang_disposeTokens(self.translationUnit, clangTokens, numTokens);
    return tokens;
}

@end
