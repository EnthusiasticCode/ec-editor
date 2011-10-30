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

@class SyntaxColoringOperation;

@interface ACFileDocument ()
{
    NSOperationQueue *_parserQueue;
}

@property (nonatomic, strong) NSMutableAttributedString *contentString;
@property (nonatomic, strong) id<ECCodeParser>codeParser;
@property (nonatomic, strong, readonly) SyntaxColoringOperation *_syntaxColoringOperation;
@property (nonatomic, strong, readonly) ECTextStyle *defaultTextStyle;

@property (nonatomic) NSRange _dirtyRange;
- (void)_queueSyntaxColoringOperationForTextRenderer:(ECTextRenderer *)textRenderer;

@end


@interface SyntaxColoringOperation : NSOperation {
    __weak ACFileDocument *_document;
    __weak ECTextRenderer *_textRenderer;
}

- (id)initWithDocument:(ACFileDocument *)document textRenderer:(ECTextRenderer *)textRenderer;

@end

#pragma mark - Implementations

#pragma mark -

@implementation SyntaxColoringOperation

- (id)initWithDocument:(ACFileDocument *)document textRenderer:(ECTextRenderer *)textRenderer
{
    if (!document)
        return nil;
    self = [super init];
    if (!self)
        return nil;
    _document = document;
    _textRenderer = textRenderer;
    return self;
}

#define CHECK_CANCELED_RETURN if (self.isCancelled || !_document || _document._syntaxColoringOperation != self) return

- (void)main
{
    CHECK_CANCELED_RETURN;
    
    NSMutableAttributedString *string = [_document.contentString mutableCopy];
    if (![string length])
        return;
    
    CHECK_CANCELED_RETURN;
    
    NSRange stringRange = NSMakeRange(0, [string length]);
    [_document.codeParser visitScopesInRange:stringRange usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
//        NSLog(@"visited scope: %@ at range: {%d,%d}", scope, scopeRange.location, scopeRange.length);
        
        if (isLeafScope)
        {
            [string setAttributes:[_document.theme attributesForScopeStack:scopesStack] range:scopeRange];
        }
        
        CHECK_CANCELED_RETURN ECCodeVisitorResultBreak;
        return ECCodeVisitorResultRecurse;
    }];
    
    CHECK_CANCELED_RETURN;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _document.contentString = string;
        _document._dirtyRange = NSMakeRange(0, 0);
        [_textRenderer updateTextFromStringRange:stringRange toStringRange:stringRange];
    }];
}

@end

#pragma mark -

@implementation ACFileDocument

@synthesize contentString = _contentString;
@synthesize codeParser = _codeParser;
@synthesize defaultTextStyle = _defaultTextStyle;
@synthesize theme = _theme;
@synthesize _syntaxColoringOperation = __syntaxColoringOperation, _dirtyRange = __dirtyRange;

- (void)setContentString:(NSMutableAttributedString *)contentString
{
    if (contentString == _contentString)
        return;
    [self willChangeValueForKey:@"contentString"];
    _contentString = contentString;
    [self updateChangeCount:UIDocumentChangeDone];
    [self didChangeValueForKey:@"contentString"];
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
            }];
            __dirtyRange = NSMakeRange(0, self.contentString.length);
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
    if (NSIntersectionRange(stringRange, __dirtyRange).length > 0)
        [self _queueSyntaxColoringOperationForTextRenderer:sender];
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
    [self _queueSyntaxColoringOperationForTextRenderer:codeView.renderer];
}

#pragma mark - Private Methods

- (void)_queueSyntaxColoringOperationForTextRenderer:(ECTextRenderer *)textRenderer
{
    if (self.theme == nil)
        return;
    
    [self willChangeValueForKey:@"_syntaxColoringOperation"];
    [__syntaxColoringOperation cancel];
    __weak id this = self;
    __syntaxColoringOperation = [[SyntaxColoringOperation alloc] initWithDocument:this textRenderer:textRenderer];
    [_parserQueue addOperation:__syntaxColoringOperation];
    [self didChangeValueForKey:@"_syntaxColoringOperation"];
}


@end
