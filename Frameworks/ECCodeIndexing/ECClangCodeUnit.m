//
//  ECClangTranslationUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangHelperFunctions.h"
#import "ECClangCodeUnit.h"
#import "ECClangCodeIndex.h"
#import "ECClangCodeCursor.h"

#import "ECCodeToken.h"
#import "ECCodeFixIt.h"
#import "ECCodeDiagnostic.h"
#import "ECCodeCompletionResult.h"
#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"
#import "ECCodeCursor.h"

NSString *const ECClangCodeUnitOptionLanguage = @"Language";
NSString *const ECClangCodeUnitOptionCXIndex = @"CXIndex";

@interface ECClangCodeUnit ()
@property (nonatomic) CXIndex index;
@property (nonatomic) CXTranslationUnit translationUnit;
@property (nonatomic) CXFile source;
@property (nonatomic, strong) NSString *file;
@property (nonatomic, strong) NSString *language;
@end

@implementation ECClangCodeUnit

@synthesize index = index_;
@synthesize translationUnit = translationUnit_;
@synthesize source = source_;
@synthesize file = file_;
@synthesize language = language_;

- (void)dealloc {
    clang_disposeTranslationUnit(self.translationUnit);
}

- (id)initWithFile:(NSString *)file index:(CXIndex)index language:(NSString *)language
{
    self = [super init];
    if (!self)
        return nil;
    if (!index)
    {
        return nil;
    }
    int parameter_count = 11;
    const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/3.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
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
    return codeUnit;
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
        [completions addObject:ECCodeCompletionResultFromClangCompletionResult(clangCompletions->Results[i])];
    clang_disposeCodeCompleteResults(clangCompletions);
    return completions;
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
        [tokens addObject:ECCodeTokenFromClangToken(self.translationUnit, clangTokens[i], attachCursors, clangTokenCursors[i])];
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

- (ECCodeCursor *)cursor
{
    return [ECClangCodeCursor cursorWithCXCursor:clang_getTranslationUnitCursor(translationUnit_)];
}

- (ECCodeCursor *)cursorForOffset:(NSUInteger)offset
{
    CXSourceLocation clangLocation = clang_getLocationForOffset(translationUnit_, clang_getFile(translationUnit_, [self.file fileSystemRepresentation]), offset);
    ECASSERT(!clang_equalLocations(clangLocation, clang_getNullLocation()));
    return [ECClangCodeCursor cursorWithCXCursor:clang_getCursor(translationUnit_, clangLocation)];
}

@end
