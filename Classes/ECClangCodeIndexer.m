//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeIndexer.h"

#import "ECCodeCompletionString.h"

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
    self = [super init];
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

- (NSRange)completionRangeWithSelection:(NSRange)selection inString:(NSString *)string
{
    if (selection.length || !selection.location) return NSMakeRange(NSNotFound, 0); //range of text is selected or caret is at beginning of file
    
    NSUInteger precedingCharacterIndex = selection.location - 1;
    NSUInteger precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
    
    if (precedingCharacter < 65 || precedingCharacter > 122) return NSMakeRange(NSNotFound, 0); //character is not a letter
    
    while (precedingCharacterIndex)
    {
        if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
        {
            NSUInteger length = selection.location - (precedingCharacterIndex + 1);
            if (length)
                return NSMakeRange(precedingCharacterIndex + 1, length);
        }
        precedingCharacterIndex--;
        precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
    }
    return NSMakeRange(0, selection.location); //if control has reached this point all character between the caret and the beginning of file are letters
}

- (NSArray *)completionsWithSelection:(NSRange)selection inString:(NSString *)string;
{    
    NSRange replacementRange = [self completionRangeWithSelection:selection inString:string];
    NSArray *guesses = [self.textChecker guessesForWordRange:replacementRange inString:string language:@"en_US"];
    NSMutableArray *completions = [[[NSMutableArray alloc] init] autorelease];
    for (NSString *guess in guesses)
    {
        [completions addObject:[ECCodeCompletionString completionWithReplacementRange:replacementRange label:guess string:[guess stringByAppendingString:@" "]]];
    }
    return completions;
}

@end
