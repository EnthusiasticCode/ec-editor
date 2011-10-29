//
//  ACFileDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileDocument.h"
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/TMTheme.h>
#import <ECUIKit/ECTextStyle.h>

static NSRange intersectionOfRangeRelativeToRange(NSRange range, NSRange inRange)
{
    NSRange intersectionRange = NSIntersectionRange(range, inRange);
    intersectionRange.location -= inRange.location;
    return intersectionRange;
}

@interface SyntaxColoringOperation : NSOperation
{
    __weak ACFileDocument *_document;
    __weak NSMutableAttributedString *_string;
}
- (id)initWithDocument:(ACFileDocument *)document;
@end

@interface ACFileDocument ()
{
    NSOperationQueue *_parserQueue;
    NSMutableSet *__callers;
}
@property (nonatomic, strong) NSMutableAttributedString *contentString;
@property (nonatomic, strong) id<ECCodeParser>codeParser;
@property (nonatomic, strong, readonly) SyntaxColoringOperation *_syntaxColoringOperation;
@property (nonatomic, strong, readonly) ECTextStyle *defaultTextStyle;
- (void)_queueSyntaxColoringOperation;
- (NSSet *)_callers;
- (void)_addCaller:(id)caller;
@end

@implementation SyntaxColoringOperation

- (id)initWithDocument:(ACFileDocument *)document
{
    if (!document)
        return nil;
    self = [super init];
    if (!self)
        return nil;
    _document = document;
    return self;
}

- (void)main
{
    if (self.isCancelled || !_document || _document._syntaxColoringOperation != self)
        return;
    NSMutableAttributedString *string = _document.contentString;
    if (![string length])
        return;
    if (self.isCancelled || !_document || _document._syntaxColoringOperation != self)
        return;
    NSRange stringRange = NSMakeRange(0, [string length]);
    [_document.codeParser visitScopesInRange:stringRange usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
        NSLog(@"visited scope: %@ at range: {%d,%d}", scope, scopeRange.location, scopeRange.length);
        if (self.isCancelled || !_document || _document._syntaxColoringOperation != self)
            return ECCodeVisitorResultBreak;
        return ECCodeVisitorResultRecurse;
    }];
    // [self.contentString ... (apply styles to result)];
    if (self.isCancelled || !_document || _document._syntaxColoringOperation != self)
        return;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        for (id caller in [_document _callers])
            [caller updateTextFromStringRange:stringRange toStringRange:stringRange];
    }];
}

@end

@implementation ACFileDocument

@synthesize contentString = _contentString;
@synthesize codeParser = _codeParser;
@synthesize _syntaxColoringOperation = __syntaxColoringOperation;
@synthesize defaultTextStyle = _defaultTextStyle;
@synthesize theme = _theme;

- (void)setContentString:(NSMutableAttributedString *)contentString
{
    if (contentString == _contentString)
        return;
    [self willChangeValueForKey:@"contentString"];
    _contentString = contentString;
    [self updateChangeCount:UIDocumentChangeDone];
    [self didChangeValueForKey:@"contentString"];
}

- (TMTheme *)theme
{
    if (!_theme)
        _theme = [TMTheme themeWithName:[[TMTheme themeNames] lastObject]];
    return _theme;
}

#pragma mark - UIDocument methods

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super openWithCompletionHandler:^(BOOL success){
        if (success)
        {
            _parserQueue = [[NSOperationQueue alloc] init];
            _parserQueue.maxConcurrentOperationCount = 1;
            ECCodeIndex *codeIndex = [[ECCodeIndex alloc] init];
            __weak ACFileDocument *this = self;
            [_parserQueue addOperationWithBlock:^{
                if (!this)
                    return;
                id<ECCodeParser> codeParser = (id<ECCodeParser>)[codeIndex codeUnitImplementingProtocol:@protocol(ECCodeParser) withFile:this.fileURL language:nil scope:nil];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    this.codeParser = codeParser;
                }];
                [this _queueSyntaxColoringOperation];
            }];
            
        }
        completionHandler(success);
    }];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super closeWithCompletionHandler:^(BOOL success){
        ECASSERT(success);
        self.codeParser = nil;
        [_parserQueue cancelAllOperations];
        _parserQueue = nil;
        completionHandler(success);
    }];
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [[self.contentString string] dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    // TODO handle error
    self.contentString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:NULL] attributes:self.defaultTextStyle.CTAttributes];
    return YES;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(ECTextRenderer *)sender
{
    return [self.contentString length];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    [self _addCaller:sender];
    return [self.contentString attributedSubstringFromRange:stringRange];
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    if ([commitString length] != 0)
    {
        [self.contentString replaceCharactersInRange:range withString:commitString];
        [self updateChangeCount:UIDocumentChangeDone];
    }
    else
    {
        [self.contentString deleteCharactersInRange:range];
        [self updateChangeCount:UIDocumentChangeDone];
    }
    [self _queueSyntaxColoringOperation];
}

#pragma mark - Private Methods

- (void)_queueSyntaxColoringOperation
{
    [self willChangeValueForKey:@"_syntaxColoringOperation"];
    [__syntaxColoringOperation cancel];
    __weak id this = self;
    __syntaxColoringOperation = [[SyntaxColoringOperation alloc] initWithDocument:this];
    [_parserQueue addOperation:__syntaxColoringOperation];
    [self didChangeValueForKey:@"_syntaxColoringOperation"];
}

- (NSArray *)_callers
{
    NSSet *callersToDiscard = [__callers objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        if (![obj respondsToSelector:@selector(dataSource)] || ![obj respondsToSelector:@selector(updateTextFromStringRange:toStringRange:)])
            return YES;
        if ((id)[obj dataSource] != self)
            return YES;
        return NO;
    }];
    [__callers minusSet:callersToDiscard];
    return [__callers copy];
}

- (void)_addCaller:(id)caller
{
    if (![caller respondsToSelector:@selector(dataSource)] || ![caller respondsToSelector:@selector(updateTextFromStringRange:toStringRange:)])
        return;
    if ((id)[caller dataSource] != self)
        return;
    [__callers addObject:caller];
}

@end
