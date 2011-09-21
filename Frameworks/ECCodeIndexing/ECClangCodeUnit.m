//
//  ECClangTranslationUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexing+PrivateInitializers.h"

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
@property (nonatomic, strong) ECCodeIndex *index;
@property (nonatomic, readonly) CXIndex clangIndex;
@property (nonatomic) CXTranslationUnit translationUnit;
@property (nonatomic) CXFile source;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *language;
@end

@implementation ECClangCodeUnit

@synthesize index = _index;
@synthesize translationUnit = _translationUnit;
@synthesize source = _source;
@synthesize fileURL = _fileURL;
@synthesize language = _language;

- (CXIndex)clangIndex
{
    return [(ECClangCodeIndex *)self.index index];
}

- (void)dealloc {
    clang_disposeTranslationUnit(self.translationUnit);
}

- (id)initWithIndex:(ECCodeIndex *)index fileURL:(NSURL *)fileURL language:(NSString *)language
{
    ECASSERT([index isKindOfClass:[ECClangCodeIndex class]]);
    ECASSERT([fileURL isFileURL]);
    self = [super init];
    if (!self)
        return nil;
    int parameter_count = 11;
    const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/3.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
    self.index = (ECClangCodeIndex *)index;
    self.translationUnit = clang_parseTranslationUnit(self.clangIndex, [[fileURL path] fileSystemRepresentation], parameters, parameter_count, 0, 0, CXTranslationUnit_PrecompiledPreamble | CXTranslationUnit_CacheCompletionResults);
    self.source = clang_getFile(self.translationUnit, [[fileURL path] fileSystemRepresentation]);
    self.fileURL = fileURL;
    
    return self;
}

- (NSArray *)completionsAtOffset:(NSUInteger)offset
{
    CXSourceLocation selectionLocation = clang_getLocationForOffset(self.translationUnit, self.source, offset);
    unsigned line;
    unsigned column;
    clang_getInstantiationLocation(selectionLocation, NULL, &line, &column, NULL);
    CXCodeCompleteResults *clangCompletions = clang_codeCompleteAt(self.translationUnit, [[self.fileURL path] fileSystemRepresentation], line, column, NULL, 0, clang_defaultCodeCompleteOptions());
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
    NSUInteger fileLength = [[NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:NULL] length];
    return [self tokensInRange:NSMakeRange(0, fileLength) withCursors:attachCursors];
}

- (ECCodeCursor *)cursor
{
    return [ECClangCodeCursor cursorWithCXCursor:clang_getTranslationUnitCursor(self.translationUnit)];
}

- (ECCodeCursor *)cursorForOffset:(NSUInteger)offset
{
    CXSourceLocation clangLocation = clang_getLocationForOffset(self.translationUnit, clang_getFile(self.translationUnit, [[self.fileURL path] fileSystemRepresentation]), offset);
    ECASSERT(!clang_equalLocations(clangLocation, clang_getNullLocation()));
    return [ECClangCodeCursor cursorWithCXCursor:clang_getCursor(self.translationUnit, clangLocation)];
}

@end
