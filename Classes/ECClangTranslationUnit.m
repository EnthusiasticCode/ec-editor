//
//  ECClangTranslationUnit.m
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangTranslationUnit.h"
#import "ECDiagnostic.h"
#import "ECSourceLocation.h"
#import "ECSourceRange.h"
#import "ECFixIt.h"

@interface ECClangTranslationUnit()
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

@implementation ECClangTranslationUnit

@synthesize diagnostics = _diagnostics;
@synthesize translationUnit = _translationUnit;

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
        clang_disposeTranslationUnit(_translationUnit);
    [_diagnostics release];
    [super dealloc];
}

- (id)initWithIndex:(CXIndex)index source:(NSString *)source language:(ECClangLanguage)language options:(NSDictionary *)options
{
    self = [super init];
    if (self)
    {
        int parameter_count = 10;
        const char const *parameters[] = {"-ObjC", "-nostdinc", "-nobuiltininc", "-I/Xcode4//usr/lib/clang/2.0/include", "-I/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/usr/include", "-F/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/System/Library/Frameworks", "-isysroot=/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.2"};
        self.translationUnit = clang_parseTranslationUnit(index, [source cStringUsingEncoding:NSUTF8StringEncoding], parameters, parameter_count, 0, 0, CXTranslationUnit_PrecompiledPreamble | CXTranslationUnit_CacheCompletionResults);
    }
    return self;
}

- (id)initWithIndex:(CXIndex)index source:(NSString *)source
{
    return [self initWithIndex:index source:source language:ECClangLanguage_ObjectiveC options:nil];
}

@end
