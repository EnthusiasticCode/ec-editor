//
//  ACFileDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileDocument.h"
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/TMTheme.h>
#import <ECUIKit/ECTextStyle.h>
#import <CoreText/CoreText.h>

@class SyntaxColoringOperation;

@interface ACFileDocument ()
{
    NSOperationQueue *_parserQueue;
    NSUInteger _lineCount;
}

@property (nonatomic, strong) NSMutableAttributedString *contentString;
@property (nonatomic, strong) ECCodeUnit *codeUnit;
@property (nonatomic, strong, readonly) SyntaxColoringOperation *_syntaxColoringOperation;

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

@implementation ACFileDocument

#pragma mark - Properties

@synthesize contentString = _contentString, codeUnit = _codeUnit;
@synthesize theme = _theme, defaultTextAttributes;
@synthesize _syntaxColoringOperation = __syntaxColoringOperation, _dirtyRange = __dirtyRange;

- (void)setContentString:(NSMutableAttributedString *)contentString
{
    if (contentString == _contentString)
        return;
    [self willChangeValueForKey:@"contentString"];
    _lineCount = NSUIntegerMax;
    _contentString = contentString;
    [self updateChangeCount:UIDocumentChangeDone];
    [self didChangeValueForKey:@"contentString"];
}

- (NSDictionary *)defaultTextAttributes
{
    if (!defaultTextAttributes)
    {
        CTFontRef defaultFont = CTFontCreateWithName((__bridge CFStringRef)@"Inconsolata-dz", 16, NULL);
        defaultTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                 (__bridge id)defaultFont, kCTFontAttributeName,
                                 [NSNumber numberWithInt:0], kCTLigatureAttributeName, nil];
        CFRelease(defaultFont);
    }
    return defaultTextAttributes;
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
                ECCodeUnit *codeUnit = [codeIndex codeUnitForFile:this.fileURL scope:nil];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    this.codeUnit = codeUnit;
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
        self.codeUnit = nil;
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
    self.contentString = [[NSMutableAttributedString alloc] initWithString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding] attributes:self.defaultTextAttributes];
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
    _lineCount = NSUIntegerMax;
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

#pragma mark - Content Information Methods

- (NSUInteger)lineCount
{
    if (_lineCount == NSUIntegerMax)
    {
        NSString *string = [_contentString string];
        unsigned index, stringLength = [string length];
        for (index = 0, _lineCount = 0; index < stringLength; ++_lineCount)
            index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);
    }
    return _lineCount;
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
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:_document.contentString.string attributes:_document.defaultTextAttributes];
    if (![string length])
        return;
    
    CHECK_CANCELED_RETURN;
    
    NSRange stringRange = NSMakeRange(0, [string length]);

    for (id<ECCodeToken>token in [_document.codeUnit annotatedTokens])
    {
        CHECK_CANCELED_RETURN;
//        NSLog(@"%@ : %@", NSStringFromRange([token range]), [token scopeIdentifier]);
        [string addAttributes:[_document.theme attributesForScopeStack:[token scopeIdentifiersStack]] range:[token range]];
        CHECK_CANCELED_RETURN;
    }
    
    CHECK_CANCELED_RETURN;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _document.contentString = string;
        _document._dirtyRange = NSMakeRange(0, 0);
        [_textRenderer updateTextFromStringRange:stringRange toStringRange:stringRange];
    }];
}

@end
