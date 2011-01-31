//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Index.h"
#import "ECClangCodeIndexer.h"

#import "ECCompletionResult.h"
#import "ECCompletionString.h"
#import "ECCompletionChunk.h"

#import <objc/message.h>


@interface ECClangCodeIndexer()
@property (nonatomic,retain) NSMutableDictionary *translationUnits;
@end

@implementation ECClangCodeIndexer


@synthesize textChecker = _textChecker;
@synthesize cIndex = _cIndex;
@synthesize translationUnits = _translationUnits;

- (UITextChecker *)textChecker
{
    if (!_textChecker)
        _textChecker = [[UITextChecker alloc] init];
    return _textChecker;
}

- (NSDictionary *)translationUnits
{
    if (!_translationUnits)
        _translationUnits = [[NSMutableDictionary alloc] init];
    return _translationUnits;
}

- (id)init
{
    // crazy hack to send init to grandparent class instead of parent class, needed to init instances of class cluster without looping
    struct objc_super grandsuper;
    grandsuper.receiver = self;
    grandsuper.super_class = [[self superclass] superclass];
    self = objc_msgSendSuper(&grandsuper, _cmd);
    if (self)
    {
        _cIndex = clang_createIndex(0, 0);
    }
    return self;
}

- (void)dealloc
{
    for (NSString *file in [self.translationUnits allKeys])
    {
        NSData *translationUnitWrapper = [self.translationUnits objectForKey:file];
        [self.translationUnits removeObjectForKey:file];
        if (!translationUnitWrapper)
            continue;
        CXTranslationUnit translationUnit = [translationUnitWrapper bytes];
        if (!translationUnit)
            continue;
        clang_disposeTranslationUnit(translationUnit);
    }
    self.translationUnits = nil;
    clang_disposeIndex(_cIndex);
    self.textChecker = nil;
    [super dealloc];
}

- (void)loadFile:(NSString *)file
{
    if (!file || ![file length])
        return;
    int parameter_count = 10;
    const char const *parameters[] = {"-ObjC", "-nostdinc", "-nobuiltininc", "-I/Xcode4//usr/lib/clang/2.0/include", "-I/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/usr/include", "-F/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/System/Library/Frameworks", "-isysroot=/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.2"};
    CXTranslationUnit TranslationUnit = clang_parseTranslationUnit(self.cIndex, [file cStringUsingEncoding:NSUTF8StringEncoding], parameters, parameter_count, 0, 0, CXTranslationUnit_None);
    int numDiagnostics = clang_getNumDiagnostics(TranslationUnit);
    for (int i = 0; i < numDiagnostics; i++)
    {
        CXDiagnostic Diagnostic = clang_getDiagnostic(TranslationUnit, i);
        CXString String = clang_formatDiagnostic(Diagnostic, clang_defaultDiagnosticDisplayOptions());
        NSLog(@"%s", clang_getCString(String));
        clang_disposeString(String);
        clang_disposeDiagnostic(Diagnostic);
    }
    NSData *translationUnitWrapper = [NSData dataWithBytesNoCopy:TranslationUnit length:sizeof(TranslationUnit)];
    [self.translationUnits setValue:translationUnitWrapper forKey:file];
}

- (void)unloadFile:(NSString *)file
{
    NSData *translationUnitWrapper = [self.translationUnits valueForKey:file];
    [self.translationUnits removeObjectForKey:file];
    if (!translationUnitWrapper)
        return;
    CXTranslationUnit translationUnit = [translationUnitWrapper bytes];
    if (!translationUnit)
        return;
    clang_disposeTranslationUnit(translationUnit);
}

- (NSArray *)files
{
    return [self.translationUnits allKeys];
}

- (NSArray *)completionsWithSelection:(NSRange)selection inString:(NSString *)string;
{    
    NSRange replacementRange = [self completionRangeWithSelection:selection inString:string];
    NSArray *guesses = [self.textChecker guessesForWordRange:replacementRange inString:string language:@"en_US"];
    NSMutableArray *completions = [[[NSMutableArray alloc] init] autorelease];
    for (NSString *guess in guesses)
    {
        [completions addObject:[ECCompletionString stringWithCompletionChunks:[NSArray arrayWithObject:[ECCompletionChunk chunkWithKind:CXCompletionChunk_TypedText string:guess]]]];
    }
    return completions;
}

@end
