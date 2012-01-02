//
//  ECClangCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeUnit.h"
#import "ECClangCodeCompletionResultSet.h"
#import "ECClangCodeDiagnostic.h"
#import "ClangHelperFunctions.h"
#import <ECFoundation/ECFileBuffer.h>

@interface ECClangCodeUnit ()
{
    ECCodeUnit *_codeUnit;
    CXIndex _clangIndex;
    CXTranslationUnit _clangUnit;
    CXFile _clangFile;
    BOOL _fileBufferHasUnparsedChanges;
    id _fileBufferObserver;
}
- (void)_reparse;
@end

@implementation ECClangCodeUnit

+ (void)load
{
    NSArray *scopes = [NSArray arrayWithObjects:@"source.c", @"source.objc", @"source.objc++", @"source.c++", nil];
    for (NSString *scope in scopes)
        [ECCodeUnit registerExtension:self forScopeIdentifier:scope forKey:ClangExtensionKey];
}

- (id)initWithCodeUnit:(ECCodeUnit *)codeUnit
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
//        int parameter_count = 11;
//        const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/3.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
//        const char * clangFilePath = [[[[self fileBuffer] fileURL] path] fileSystemRepresentation];
//        NSString *contents = [[self fileBuffer] stringInRange:NSMakeRange(0, [[self fileBuffer] length])];
//        struct CXUnsavedFile clangFileBuffer = {[[[[self fileBuffer] fileURL] path] fileSystemRepresentation], [contents UTF8String], [contents length]};
//        _clangUnit = clang_parseTranslationUnit(_clangIndex, clangFilePath, parameters, parameter_count, &clangFileBuffer, 1, clang_defaultEditingTranslationUnitOptions());
//        _clangFile = clang_getFile(_clangUnit, clangFilePath);
    }
    return _clangUnit;
}

- (id<ECCodeCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return [[ECClangCodeCompletionResultSet alloc] initWithCodeUnit:_codeUnit atOffset:offset];
}

- (NSArray *)diagnostics
{
    if (_fileBufferHasUnparsedChanges)
        [self _reparse];
    NSMutableArray *diagnostics = [NSMutableArray array];
    NSUInteger numDiagnostics = clang_getNumDiagnostics(_clangUnit);
    for (NSUInteger diagnosticIndex = 0; diagnosticIndex < numDiagnostics; ++diagnosticIndex)
        [diagnostics addObject:[[ECClangCodeDiagnostic alloc] initWithClangDiagnostic:clang_getDiagnostic(_clangUnit, diagnosticIndex)]];
    return diagnostics;
}

- (void)_reparse
{
    // TODO: reparse does not work at the moment, try again in a while after updating clang
//    clang_reparseTranslationUnit(_clangUnit, 1, &clangFileBuffer, clang_defaultReparseOptions(_clangUnit));
    _clangFile = NULL;
    clang_disposeTranslationUnit(_clangUnit);
    [self clangTranslationUnit];
}

#pragma mark - ECFileBufferConsumer

- (void)fileBuffer:(ECFileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    _fileBufferHasUnparsedChanges = YES;
}

- (void)fileBuffer:(ECFileBuffer *)fileBuffer fileWillMoveFromURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
    clang_disposeTranslationUnit(_clangUnit);
    _clangFile = NULL;
    _fileBufferHasUnparsedChanges = YES;
}

@end
