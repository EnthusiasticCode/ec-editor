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

@interface ECClangCodeUnit ()
{
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (nonatomic, strong) ECCodeIndex *index;
@property (nonatomic, readonly) CXIndex clangIndex;
@property (nonatomic) CXTranslationUnit translationUnit;
@property (nonatomic, readonly) CXFile mainSourceFile;
@property (atomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) NSDate *presentedItemLastModificationDate;
@property (nonatomic) BOOL sourceFilesContentsHaveChangesSinceLastReparse;
- (void)loadTranslationUnitForFileURL:(NSURL *)fileURL;
- (void)reparseSourceFiles;

#pragma mark - Included file observing
@property (nonatomic, strong) NSMutableDictionary *observedIncludedFiles;
- (BOOL)observeIncludedFilesDidObserveNewFiles;
- (NSSet *)includedFileURLs;
static void inclusionVisitor(CXFile included_file, CXSourceLocation* inclusion_stack, unsigned include_len, NSMutableSet **includedFileURLs);
@end

@implementation ECClangCodeUnit

@synthesize index = _index;
@synthesize translationUnit = _translationUnit;
@synthesize fileURL = _fileURL;
@synthesize language = _language;
@synthesize presentedItemLastModificationDate = _presentedItemLastModificationDate;
@synthesize sourceFilesContentsHaveChangesSinceLastReparse = _sourceFilesContentsHaveChangesSinceLastReparse;
@synthesize observedIncludedFiles = _observedIncludedFiles;

- (CXIndex)clangIndex
{
    return [(ECClangCodeIndex *)self.index index];
}

- (CXFile)mainSourceFile
{
    if (!self.translationUnit)
        return NULL;
    return clang_getFile(self.translationUnit, [[self.fileURL path] fileSystemRepresentation]);
}

- (void)dealloc {
    clang_disposeTranslationUnit(self.translationUnit);
    if ([[NSFileCoordinator filePresenters] containsObject:self])
        [NSFileCoordinator removeFilePresenter:self];
}

#pragma mark - ECCodeUnit subclass methods

- (id)initWithIndex:(ECCodeIndex *)index fileURL:(NSURL *)fileURL language:(NSString *)language
{
    ECASSERT([index isKindOfClass:[ECClangCodeIndex class]]);
    ECASSERT([fileURL isFileURL]);
    self = [super init];
    if (!self)
        return nil;
    self.language = language;
    self.index = index;
    [self loadTranslationUnitForFileURL:fileURL];
    return self;
}

- (NSArray *)completionsAtOffset:(NSUInteger)offset
{
    if (!self.translationUnit)
        return nil;
    if (self.sourceFilesContentsHaveChangesSinceLastReparse)
        [self reparseSourceFiles];
    CXSourceLocation selectionLocation = clang_getLocationForOffset(self.translationUnit, self.mainSourceFile, offset);
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
    if (self.sourceFilesContentsHaveChangesSinceLastReparse)
        [self reparseSourceFiles];
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
    if (!self.translationUnit)
        return nil;
    if (self.sourceFilesContentsHaveChangesSinceLastReparse)
        [self reparseSourceFiles];
    return nil;
}

- (NSArray *)tokensInRange:(NSRange)range withCursors:(BOOL)attachCursors
{
    if (!self.translationUnit)
        return nil;
    if (self.sourceFilesContentsHaveChangesSinceLastReparse)
        [self reparseSourceFiles];
    unsigned numTokens;
    CXToken *clangTokens;
    CXSourceLocation clangStart = clang_getLocationForOffset(self.translationUnit, self.mainSourceFile, range.location);
    CXSourceLocation clangEnd = clang_getLocationForOffset(self.translationUnit, self.mainSourceFile, range.location + range.length);
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

- (ECCodeCursor *)cursor
{
    if (!self.translationUnit)
        return nil;
    return [ECClangCodeCursor cursorWithCXCursor:clang_getTranslationUnitCursor(self.translationUnit)];
}

- (ECCodeCursor *)cursorForOffset:(NSUInteger)offset
{
    if (!self.translationUnit)
        return nil;
    if (self.sourceFilesContentsHaveChangesSinceLastReparse)
        [self reparseSourceFiles];
    CXSourceLocation clangLocation = clang_getLocationForOffset(self.translationUnit, clang_getFile(self.translationUnit, [[self.fileURL path] fileSystemRepresentation]), offset);
    ECASSERT(!clang_equalLocations(clangLocation, clang_getNullLocation()));
    return [ECClangCodeCursor cursorWithCXCursor:clang_getCursor(self.translationUnit, clangLocation)];
}

#pragma mark - Translation unit management

- (void)loadTranslationUnitForFileURL:(NSURL *)fileURL
{
    if (self.translationUnit)
        clang_disposeTranslationUnit(self.translationUnit);
    self.observedIncludedFiles = nil;
    self.fileURL = nil;
    if ([[NSFileCoordinator filePresenters] containsObject:self])
        [NSFileCoordinator removeFilePresenter:self];
    if (!fileURL)
        return;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    __weak ECClangCodeUnit *this = self;
    [fileCoordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        id lastModificationDate;
        [newURL getResourceValue:&lastModificationDate forKey:NSURLContentModificationDateKey error:NULL];
        this.presentedItemLastModificationDate = lastModificationDate;
        int parameter_count = 11;
        const char const *parameters[] = {"-ObjC", "-fobjc-nonfragile-abi", "-nostdinc", "-nobuiltininc", "-I/Developer/usr/lib/clang/3.0/include", "-I/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include", "-F/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/System/Library/Frameworks", "-isysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.3"};
        this.translationUnit = clang_parseTranslationUnit(this.clangIndex, [[newURL path] fileSystemRepresentation], parameters, parameter_count, 0, 0, clang_defaultEditingTranslationUnitOptions());
        this.fileURL = newURL;
        [NSFileCoordinator addFilePresenter:self];
    }];
}

- (void)reparseSourceFiles
{
    if (!self.translationUnit)
        return;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    __weak ECClangCodeUnit *this = self;
    do
    {
        [fileCoordinator prepareForReadingItemsAtURLs:[self.observedIncludedFiles allKeys] options:NSFileCoordinatorReadingResolvesSymbolicLink writingItemsAtURLs:nil options:0 error:NULL byAccessor:^(void(^completionHandler)(void)) {
            [fileCoordinator coordinateReadingItemAtURL:this.fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
                clang_reparseTranslationUnit(this.translationUnit, 0, NULL, clang_defaultReparseOptions(this.translationUnit));
            }];
            completionHandler();
        }];
    }
    while ([this observeIncludedFilesDidObserveNewFiles]);
    self.sourceFilesContentsHaveChangesSinceLastReparse = NO;
}

#pragma mark - NSFileCoordination

- (NSURL *)presentedItemURL
{
    return self.fileURL;
}

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL
{
    return [NSSet setWithObject:@"fileURL"];
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    if (!_presentedItemOperationQueue)
    {
        _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
        _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _presentedItemOperationQueue;
}

- (void)presentedItemDidChange
{
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    __weak ECClangCodeUnit *this = self;
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        id lastModificationDate;
        [newURL getResourceValue:&lastModificationDate forKey:NSURLContentModificationDateKey error:NULL];
        if ([this.presentedItemLastModificationDate isEqualToDate:lastModificationDate])
            return;
        this.presentedItemLastModificationDate = lastModificationDate;
        this.sourceFilesContentsHaveChangesSinceLastReparse = YES;
    }];
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    [self loadTranslationUnitForFileURL:newURL];
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    [self loadTranslationUnitForFileURL:nil];
    completionHandler(nil);
}

#pragma mark - Included files observing

- (NSMutableDictionary *)observedIncludedFiles
{
    if (!_observedIncludedFiles)
        _observedIncludedFiles = [NSMutableDictionary dictionary];
    return _observedIncludedFiles;
}

- (void)contentsOfObservedItemDidChangeForItemObserver:(ECItemObserver *)itemObserver
{
    self.sourceFilesContentsHaveChangesSinceLastReparse = YES;
}

- (BOOL)observeIncludedFilesDidObserveNewFiles
{
    NSSet *observedFileURLs = [NSSet setWithArray:[self.observedIncludedFiles allKeys]];
    NSSet *includedFileURLs = [self includedFileURLs];
    NSMutableSet *fileURLsToRemove = [NSMutableSet setWithSet:observedFileURLs];
    [fileURLsToRemove minusSet:includedFileURLs];
    NSMutableSet *fileURLsToAdd = [NSMutableSet setWithSet:includedFileURLs];
    [fileURLsToAdd minusSet:observedFileURLs];
    for (NSURL *fileURL in fileURLsToRemove)
        [self.observedIncludedFiles removeObjectForKey:fileURL];
    for (NSURL *fileURL in fileURLsToAdd)
    {
        ECItemObserver *itemObserver = [[ECItemObserver alloc] initWithItemURL:fileURL queue:self.presentedItemOperationQueue];
        itemObserver.delegate = self;
        [self.observedIncludedFiles setObject:itemObserver forKey:fileURL];
    }
    return [fileURLsToAdd count] != 0;
}

- (NSSet *)includedFileURLs
{
    if (!self.translationUnit)
        return nil;
    NSSet *includedFileURLs;
    clang_getInclusions(self.translationUnit, (CXInclusionVisitor)&inclusionVisitor, &includedFileURLs);
    return includedFileURLs;
}

static void inclusionVisitor(CXFile included_file, CXSourceLocation* inclusion_stack, unsigned include_len, NSMutableSet **includedFileURLs)
{
    ECASSERT(includedFileURLs);
    if (!*includedFileURLs)
        *includedFileURLs = [NSMutableSet set];
    CXString fileName = clang_getFileName(included_file);
    [*includedFileURLs addObject:[NSURL fileURLWithPath:[NSString stringWithCString:clang_getCString(fileName) encoding:NSUTF8StringEncoding]]];
    clang_disposeString(fileName);
}

@end
