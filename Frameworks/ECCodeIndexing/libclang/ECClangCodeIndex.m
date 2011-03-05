//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangCodeIndex.h"
#import "ECClangCodeUnit.h"

@interface ECClangCodeIndex()
@property (nonatomic) CXIndex index;
@property (nonatomic, retain) NSMutableDictionary *translationUnits;
@end

@implementation ECClangCodeIndex

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
#pragma mark ECCodeIndex

- (NSDictionary *)languageToExtensionMap
{
    NSArray *languages = [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", nil];
    NSArray *extensionForLanguages = [NSArray arrayWithObjects:@"c", @"m", @"cc", @"mm", nil];
    return [NSDictionary dictionaryWithObjects:extensionForLanguages forKeys:languages];
}

- (NSDictionary *)extensionToLanguageMap
{
    NSArray *extensions = [NSArray arrayWithObjects:@"c", @"m", @"cc", @"mm", @"h", nil];
    NSArray *languageForextensions = [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", @"C", nil];
    return [NSDictionary dictionaryWithObjects:languageForextensions forKeys:extensions];
}

- (ECCodeUnit *)unitForURL:(NSURL *)url withLanguage:(NSString *)language
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if (language)
        [options setValue:language forKey:ECClangCodeUnitOptionLanguage];
    else
        [options setValue:[self.extensionToLanguageMap objectForKey:[url pathExtension]] forKey:ECClangCodeUnitOptionLanguage];
    ECClangCodeUnit *codeUnit = [ECClangCodeUnit unitWithFile:url index:self.index options:options];
    if (!codeUnit)
        return nil;
//    [self.translationUnits setObject:translationUnit forKey:file.URL];
    return codeUnit;
}

@end
