//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangCodeIndexer.h"

#import "../ECSourceLocation.h"
#import "../ECSourceRange.h"
#import "../ECToken.h"
#import "../ECFixIt.h"
#import "../ECDiagnostic.h"
#import "../ECCompletionResult.h"
#import "../ECCompletionString.h"
#import "../ECCompletionChunk.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface ECClangCodeIndexer()
@property (nonatomic) CXIndex index;
@property (nonatomic, retain) NSMutableDictionary *files;
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

#pragma mark -
@implementation ECClangCodeIndexer

#pragma mark Properties

@synthesize files;

- (NSArray *)handledLanguages
{
    return [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", nil];
}

- (NSArray *)handledUTIs
{
    return [NSArray arrayWithObjects:@"public.c-header", @"public.c-source", @"public.objective-c-source", @"public.c-plus-plus-source", @"public.objective-c-plus-plus-source", nil];
}

- (NSSet *)handledFiles
{
    return [NSSet setWithArray:[self.files allKeys]];
}

#pragma mark Initialization

- (void)dealloc
{
    clang_disposeIndex(self.index);
    self.files = nil;
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    self.index = clang_createIndex(0, 0);
    return self;
}

#pragma mark -
#pragma mark Private methods

//- (void)reparseTranslationUnitWithUnsavedFileBuffers:(NSDictionary *)files
//{
//    if (!self.translationUnit)
//        return;
//    unsigned numUnsavedFiles = [files count];
//    struct CXUnsavedFile *unsavedFiles = malloc(numUnsavedFiles * sizeof(struct CXUnsavedFile));
//    unsigned i = 0;
//    for (NSString *file in [files allKeys]) {
//        unsavedFiles[i].Filename = [file UTF8String];
//        NSString *fileBuffer = [files objectForKey:file];
//        unsavedFiles[i].Contents = [file UTF8String];
//        unsavedFiles[i].Length = [file length];
//        i++;
//    }
//    clang_reparseTranslationUnit(self.translationUnit, numUnsavedFiles, unsavedFiles, clang_defaultReparseOptions(self.translationUnit));
//    free(unsavedFiles);
//}

#pragma mark -
#pragma mark ECCodeIndexer

- (void)addFilesObject:(NSURL *)fileURL
{
    NSString *extension = [fileURL pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
    if ([(NSString *)UTI isEqualToString:@"public.c-header"])
        _language = @"C";
    if ([(NSString *)UTI isEqualToString:@"public.c-source"])
        _language = @"C";
    if ([(NSString *)UTI isEqualToString:@"public.objective-c-source"])
        _language = @"Objective C";
    if ([(NSString *)UTI isEqualToString:@"public.c-plus-plus-source"])
        _language = @"C++";
    if ([(NSString *)UTI isEqualToString:@"public.objective-c-plus-plus-source"])
        _language = @"Objective C++";
    CFRelease(UTI);
}

- (void)removeFilesObject:(NSURL *)fileURL
{
    
}

- (void)setLanguage:(NSString *)language forFile:(NSURL *)fileURL;
{
    
}

- (void)setBuffer:(NSString *)buffer forFile:(NSURL *)fileURL;
{
    
}

- (NSArray *)completionsForFile:(NSURL *)fileURL withSelection:(NSRange)selection;
{
    
}

- (NSArray *)diagnosticsForFile:(NSURL *)fileURL;
{
    
}

- (NSArray *)fixItsForFile:(NSURL *)fileURL;
{
    
}

- (NSArray *)tokensForFile:(NSURL *)fileURL inRange:(NSRange)range;
{
    
}

- (NSArray *)tokensForFile:(NSURL *)fileURL;
{
    
}

//- (NSArray *)completionsForSelection:(NSRange)selection withUnsavedFileBuffers:(NSDictionary *)files
//{
//    CXSourceLocation selectionLocation = clang_getLocationForOffset(self.translationUnit, clang_getFile(self.translationUnit, self.sourcePath), selection.location);
//    unsigned line;
//    unsigned column;
//    clang_getInstantiationLocation(selectionLocation, NULL, &line, &column, NULL);
//    CXCodeCompleteResults *clangCompletions = clang_codeCompleteAt(self.translationUnit, self.sourcePath, line, column, NULL, 0, clang_defaultCodeCompleteOptions());
//    NSMutableArray *completions = [[[NSMutableArray alloc] init] autorelease];
//    for (unsigned i = 0; i < clangCompletions->NumResults; i++)
//        [completions addObject:completionResultFromClangCompletionResult(clangCompletions->Results[i]).completionString];
//    clang_disposeCodeCompleteResults(clangCompletions);
//    return completions;
//}
//
//- (NSArray *)diagnostics
//{
//    if (!self.translationUnit)
//        return nil;
//    unsigned numDiagnostics = clang_getNumDiagnostics(self.translationUnit);
//    NSMutableArray *diagnostics = [NSMutableArray arrayWithCapacity:numDiagnostics];
//    for (unsigned i = 0; i < numDiagnostics; i++)
//    {
//        CXDiagnostic clangDiagnostic = clang_getDiagnostic(self.translationUnit, i);
//        ECDiagnostic *diagnostic = diagnosticFromClangDiagnostic(clangDiagnostic);
//        [diagnostics addObject:diagnostic];
//        NSLog(@"%@", diagnostic);
//        clang_disposeDiagnostic(clangDiagnostic);
//    }
//    return diagnostics;
//}
//
//- (NSArray *)tokensForRange:(NSRange)range withUnsavedFileBuffers:(NSDictionary *)files
//{
//    if (!self.source)
//        return nil;
//    if (range.location == NSNotFound)
//        return nil;
//    if (files)
//        [self reparseTranslationUnitWithUnsavedFileBuffers:files];
//    unsigned numTokens;
//    CXToken *clangTokens;
//    CXFile clangFile = clang_getFile(self.translationUnit, self.sourcePath);
//    CXSourceLocation clangStart = clang_getLocationForOffset(self.translationUnit, clangFile, range.location);
//    CXSourceLocation clangEnd = clang_getLocationForOffset(self.translationUnit, clangFile, range.location + range.length);
//    CXSourceRange clangRange = clang_getRange(clangStart, clangEnd);
//    clang_tokenize(self.translationUnit, clangRange, &clangTokens, &numTokens);
//    NSMutableArray *tokens = [NSMutableArray arrayWithCapacity:numTokens];
//    for (unsigned i = 0; i < numTokens; i++)
//    {
//        [tokens addObject:tokenFromClangToken(self.translationUnit, clangTokens[i])];
//    }
//    clang_disposeTokens(self.translationUnit, clangTokens, numTokens);
//    return tokens;
//}

@end
