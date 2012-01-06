//
//  ECClangCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangUnitExtension.h"
#import "ClangIndexExtension.h"
#import "ClangCompletionResultSet.h"
#import "ClangDiagnostic.h"
#import "ClangHelperFunctions.h"
#import <ECFoundation/ECFileBuffer.h>

@interface ClangUnitExtension ()
{
    TMUnit *_codeUnit;
    CXIndex _clangIndex;
    CXTranslationUnit _clangUnit;
    BOOL _fileBufferHasUnparsedChanges;
    id _fileBufferObserver;
}
- (void)_reparse;
@end

@implementation ClangUnitExtension

+ (void)load
{
    @autoreleasepool
    {
        NSArray *languages = [NSArray arrayWithObjects:@"c", @"objc", @"objc++", @"c++", nil];
        for (NSString *language in languages)
            [TMUnit registerExtension:self forLanguageIdentifier:language forKey:ClangExtensionKey];
    }
}

- (id)initWithCodeUnit:(TMUnit *)codeUnit
{
    ECASSERT(codeUnit);
    self = [super init];
    if (!self)
        return nil;
    _codeUnit = codeUnit;
    return self;
}

- (void)dealloc
{
    clang_disposeTranslationUnit(_clangUnit);
}

- (CXTranslationUnit)clangTranslationUnit
{
    if (!_clangUnit)
    {
        int parameter_count = 11;
        const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/3.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
        const char * clangFilePath = [[[[_codeUnit fileBuffer] fileURL] path] fileSystemRepresentation];
        NSString *contents = [[_codeUnit fileBuffer] string];
        struct CXUnsavedFile clangFileBuffer = {clangFilePath, [contents UTF8String], [contents length]};
        _clangUnit = clang_parseTranslationUnit(_clangIndex, clangFilePath, parameters, parameter_count, &clangFileBuffer, 1, clang_defaultEditingTranslationUnitOptions());
    }
    return _clangUnit;
}

- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return [[ClangCompletionResultSet alloc] initWithCodeUnit:_codeUnit atOffset:offset];
}

- (NSArray *)diagnostics
{
    if (_fileBufferHasUnparsedChanges)
        [self _reparse];
    NSMutableArray *diagnostics = [NSMutableArray array];
    NSUInteger numDiagnostics = clang_getNumDiagnostics(_clangUnit);
    for (NSUInteger diagnosticIndex = 0; diagnosticIndex < numDiagnostics; ++diagnosticIndex)
        [diagnostics addObject:[[ClangDiagnostic alloc] initWithClangDiagnostic:clang_getDiagnostic(_clangUnit, diagnosticIndex)]];
    return diagnostics;
}

- (void)_reparse
{
    const char * clangFilePath = [[[[_codeUnit fileBuffer] fileURL] path] fileSystemRepresentation];
    NSString *contents = [[_codeUnit fileBuffer] string];
    struct CXUnsavedFile clangFileBuffer = {clangFilePath, [contents UTF8String], [contents length]};
    clang_reparseTranslationUnit(_clangUnit, 1, &clangFileBuffer, clang_defaultReparseOptions(_clangUnit));
}

#pragma mark - ECFileBufferConsumer

- (void)fileBuffer:(ECFileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    _fileBufferHasUnparsedChanges = YES;
}

- (void)fileBuffer:(ECFileBuffer *)fileBuffer fileWillMoveFromURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
    clang_disposeTranslationUnit(_clangUnit);
    _clangUnit = NULL;
    _fileBufferHasUnparsedChanges = YES;
}

@end
