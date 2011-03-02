//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangCodeIndexer.h"
#import "ECClangTranslationUnit.h"

#import "../ECCodeIndexingFile.h"

@interface ECClangCodeIndexer()
@property (nonatomic) CXIndex index;
@property (nonatomic, retain) NSMutableDictionary *translationUnits;
@end

@implementation ECClangCodeIndexer

#pragma mark Properties

@synthesize index = _index;
@synthesize translationUnits = _translationUnits;

#pragma mark Initialization

- (void)dealloc
{
    clang_disposeIndex(self.index);
    self.translationUnits = nil;
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    self.index = clang_createIndex(0, 0);
    self.translationUnits = [NSMutableDictionary dictionary];
    return self;
}

#pragma mark -
#pragma mark Private methods

//- (void)reparseTranslationUnitWithUnsavedFileBuffers:(NSDictionary *)translationUnits
//{
//    if (!self.translationUnit)
//        return;
//    unsigned numUnsavedFiles = [translationUnits count];
//    struct CXUnsavedFile *unsavedFiles = malloc(numUnsavedFiles * sizeof(struct CXUnsavedFile));
//    unsigned i = 0;
//    for (NSString *file in [translationUnits allKeys]) {
//        unsavedFiles[i].Filename = [file UTF8String];
//        NSString *fileBuffer = [translationUnits objectForKey:file];
//        unsavedFiles[i].Contents = [file UTF8String];
//        unsavedFiles[i].Length = [file length];
//        i++;
//    }
//    clang_reparseTranslationUnit(self.translationUnit, numUnsavedFiles, unsavedFiles, clang_defaultReparseOptions(self.translationUnit));
//    free(unsavedFiles);
//}

#pragma mark -
#pragma mark ECCodeIndexerPlugin

- (NSDictionary *)languageToExtensionMappingDictionary
{
    NSArray *languages = [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", nil];
    NSArray *extensionForLanguages = [NSArray arrayWithObjects:@"c", @"m", @"cc", @"mm", nil];
    return [NSDictionary dictionaryWithObjects:extensionForLanguages forKeys:languages];
}

- (NSDictionary *)extensionToLanguageMappingDictionary
{
    NSArray *extensions = [NSArray arrayWithObjects:@"c", @"m", @"cc", @"mm", @"h", nil];
    NSArray *languageForextensions = [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", @"C", nil];
    return [NSDictionary dictionaryWithObjects:languageForextensions forKeys:extensions];
}

- (NSSet *)loadedFiles
{
    return [NSSet setWithArray:[self.translationUnits allKeys]];
}

- (BOOL)loadFile:(ECCodeIndexingFile *)file
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if (file.language)
        [options setValue:file.language forKey:ECClangTranslationUnitOptionLanguage];
    else
        [options setValue:[self.extensionToLanguageMappingDictionary objectForKey:file.extension] forKey:ECClangTranslationUnitOptionLanguage];
    ECClangTranslationUnit *translationUnit = [ECClangTranslationUnit translationUnitWithFile:file.URL index:self.index options:options];
    if (!translationUnit)
        return NO;
    [self.translationUnits setObject:translationUnit forKey:file.URL];
    return YES;
}

- (BOOL)unloadFile:(ECCodeIndexingFile *)file
{
    [self.translationUnits removeObjectForKey:file.URL];
    return YES;
}

- (NSArray *)completionsForFile:(NSURL *)file withSelection:(NSRange)selection;
{
    return [[self.translationUnits objectForKey:file] completionsWithSelection:selection];
}

- (NSArray *)diagnosticsForFile:(NSURL *)file;
{
    return [[self.translationUnits objectForKey:file] diagnostics];
}

- (NSArray *)fixItsForFile:(NSURL *)file;
{
    return [[self.translationUnits objectForKey:file] fixIts];
}

- (NSArray *)tokensForFile:(NSURL *)file inRange:(NSRange)range;
{
    return [[self.translationUnits objectForKey:file] tokensInRange:range];
}

- (NSArray *)tokensForFile:(NSURL *)file;
{
    return [[self.translationUnits objectForKey:file] tokens];
}

@end
