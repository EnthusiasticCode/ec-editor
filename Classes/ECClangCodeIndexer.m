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

#import "ECClangTranslationUnit.h"
#import "ECDiagnostic.h"

#import <objc/message.h>


@interface ECClangCodeIndexer()
@property (nonatomic, retain) NSMutableDictionary *translationUnits;
@property (nonatomic) CXIndex cIndex;
@property (nonatomic, retain) ECClangTranslationUnit *activeTranslationUnit;
@end


@implementation ECClangCodeIndexer

@synthesize cIndex = _cIndex;
@synthesize translationUnits = _translationUnits;
@synthesize activeTranslationUnit = _activeTranslationUnit;

- (NSDictionary *)translationUnits
{
    if (!_translationUnits)
        _translationUnits = [[NSMutableDictionary alloc] init];
    return _translationUnits;
}

- (void)dealloc
{
    self.translationUnits = nil;
    self.activeTranslationUnit = nil;
    clang_disposeIndex(_cIndex);
    [super dealloc];
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

- (void)setActiveFile:(NSString *)file
{
    self.activeTranslationUnit = [self.translationUnits objectForKey:file];
}

- (void)loadFile:(NSString *)file
{
    if (!file || ![file length])
        return;
    ECClangTranslationUnit *translationUnit = [[ECClangTranslationUnit alloc] initWithIndex:self.cIndex source:file];
    for (ECDiagnostic *diagnostic in translationUnit.diagnostics)
    {
        NSLog(@"%@", diagnostic.spelling);
    }
    [self.translationUnits setValue:translationUnit forKey:file];
    self.activeTranslationUnit = translationUnit;
    [translationUnit release];
}

- (void)unloadFile:(NSString *)file
{
    [self.translationUnits removeObjectForKey:file];
}

- (NSArray *)files
{
    return [self.translationUnits allKeys];
}

- (NSArray *)completionsWithSelection:(NSRange)selection inString:(NSString *)string;
{    
//    NSRange replacementRange = [self completionRangeWithSelection:selection inString:string];
//    NSArray *guesses;
    NSMutableArray *completions = [[[NSMutableArray alloc] init] autorelease];
//    for (NSString *guess in guesses)
//    {
//        [completions addObject:[ECCompletionString stringWithCompletionChunks:[NSArray arrayWithObject:[ECCompletionChunk chunkWithKind:CXCompletionChunk_TypedText string:guess]]]];
//    }
    return completions;
}

- (NSArray *)tokensForRange:(NSRange)range inFile:(NSString *)string
{
    
}

- (NSArray *)tokensForRange:(NSRange)range
{
    
}

@end
