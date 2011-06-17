//
//  File.m
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "File.h"

#import "ECCodeIndex.h"
#import "ECCodeUnit.h"
#import "ECCodeToken.h"
#import "ECCodeCursor.h"
#import "ECCodeCompletionResult.h"
#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"

#import "ECCodeByteArrayDataSource.h"
#import "CompletionController.h"
#import "ECTextStyle.h"
#import "ECTextRange.h"

#import "ECPatriciaTrie.h"

@interface File ()
@property (nonatomic, strong) ECCodeByteArrayDataSource *byteArrayDataSource;
@property (nonatomic, strong) CompletionController *completionController;
@property (nonatomic, strong) ECCodeUnit *unit;
@end

@implementation File

@dynamic bookmarks;
@dynamic historyItems;
@dynamic undoItems;

@synthesize byteArrayDataSource = _byteArrayDataSource;
@synthesize completionController = _completionController;
@synthesize unit = _unit;

- (ECCodeByteArrayDataSource *)byteArrayDataSource
{
    if (!_byteArrayDataSource && self.path)
    {
        NSURL *url = [NSURL fileURLWithPath:[self absolutePath]];
        _byteArrayDataSource = [[ECCodeByteArrayDataSource alloc] init];
        _byteArrayDataSource.fileURL = url;
        ECCodeUnit *unit = self.unit;
        ECTextStyle *keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" font:nil color:[UIColor blueColor]];
        ECTextStyle *commentStyle = [ECTextStyle textStyleWithName:@"Comment" font:nil color:[UIColor greenColor]];
        ECTextStyle *referenceStyle = [ECTextStyle textStyleWithName:@"Reference" font:nil color:[UIColor purpleColor]];
        ECTextStyle *literalStyle = [ECTextStyle textStyleWithName:@"Literal" font:nil color:[UIColor redColor]];
        ECTextStyle *declarationStyle = [ECTextStyle textStyleWithName:@"Declaration" font:nil color:[UIColor brownColor]];
        ECTextStyle *preprocessingStyle = [ECTextStyle textStyleWithName:@"Preprocessing" font:nil color:[UIColor orangeColor]];
        self.byteArrayDataSource.stylizeBlock = ^(ECCodeByteArrayDataSource *dataSource, NSMutableAttributedString *string, NSRange stringRange)
        {
            for (ECCodeToken *token in [unit tokensInRange:stringRange withCursors:YES])
            {
                switch (token.kind)
                {
                    case ECCodeTokenKindKeyword:
                        [string addAttributes:keywordStyle.CTAttributes range:token.extent];
                        break;
                    case ECCodeTokenKindComment:
                        [string addAttributes:commentStyle.CTAttributes range:token.extent];
                        break;
                    case ECCodeTokenKindLiteral:
                        [string addAttributes:literalStyle.CTAttributes range:token.extent];
                        break;
                    default:
                        if (token.cursor.kind >= ECCodeCursorKindFirstDecl && token.cursor.kind <= ECCodeCursorKindLastDecl)
                            [string addAttributes:declarationStyle.CTAttributes range:token.extent];
                        else if (token.cursor.kind >= ECCodeCursorKindFirstRef && token.cursor.kind <= ECCodeCursorKindLastRef)
                            [string addAttributes:referenceStyle.CTAttributes range:token.extent];
                        else if (token.cursor.kind >= ECCodeCursorKindFirstPreprocessing && token.cursor.kind <= ECCodeCursorKindLastPreprocessing)
                            [string addAttributes:preprocessingStyle.CTAttributes range:token.extent];
                        break;
                }
            }
        };
    }
    return _byteArrayDataSource;
}

- (CompletionController *)completionController
{
    if (!_completionController && self.unit)
        _completionController = [[CompletionController alloc] initWithNibName:@"CompletionController" bundle:[NSBundle mainBundle]];
    return _completionController;
}

- (ECCodeUnit *)unit
{
    if (!_unit && self.byteArrayDataSource)
    {
        ECCodeIndex *index = [[ECCodeIndex alloc] init];
        _unit = [index unitForFile:[self absolutePath]];
    }
    return _unit;
}

- (void)didTurnIntoFault
{
    self.byteArrayDataSource = nil;
    self.completionController = nil;
    self.unit = nil;
    [super didTurnIntoFault];
}

#pragma mark - Methods forwarded to data source

- (NSUInteger)textLength
{
    return [self.byteArrayDataSource textLength];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString
{
    return [self.byteArrayDataSource textRenderer:sender stringInLineRange:lineRange endOfString:endOfString];
}

- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength
{
    return [self.byteArrayDataSource textRenderer:sender estimatedTextLineCountOfLength:maximumLineLength];
}

- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range
{
    return [self.byteArrayDataSource codeView:codeView stringInRange:range];
}

- (BOOL)codeView:(ECCodeView *)codeView canEditTextInRange:(NSRange)range
{
    return [self.byteArrayDataSource codeView:codeView canEditTextInRange:range];
}

- (void)codeView:(ECCodeView *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range
{
    return [self.byteArrayDataSource codeView:codeView commitString:string forTextInRange:range];
}

- (UIViewController *)codeView:(ECCodeView *)codeView viewControllerForCompletionAtTextInRange:(NSRange)range
{
    NSArray *array = [self.unit completionsWithSelection:range];
    ECPatriciaTrie *trie = [[ECPatriciaTrie alloc] init];
    for (ECCodeCompletionResult *result in array)
        [trie setObject:result forKey:[result.completionString typedText]];
    self.completionController.results = trie;
    self.completionController.match = @"";
    return self.completionController;
}

@end
