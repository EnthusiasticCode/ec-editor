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
#import <ECCodeIndexing/ECCodeToken.h>
#import <ECCodeIndexing/ECCodeCursor.h>
#import <ECUIKit/ECTextStyle.h>

static NSRange intersectionOfRangeRelativeToRange(NSRange range, NSRange inRange)
{
    NSRange intersectionRange = NSIntersectionRange(range, inRange);
    intersectionRange.location -= inRange.location;
    return intersectionRange;
}

@interface ACFileDocument ()
@property (nonatomic, strong) NSString *contentString;
@property (nonatomic, strong) ECCodeUnit *codeUnit;
@property (nonatomic, strong, readonly) ECTextStyle *defaultTextStyle;
@property (nonatomic, strong, readonly) ECTextStyle *keywordStyle;
@property (nonatomic, strong, readonly) ECTextStyle *commentStyle;
@property (nonatomic, strong, readonly) ECTextStyle *referenceStyle;
@property (nonatomic, strong, readonly) ECTextStyle *literalStyle;
@property (nonatomic, strong, readonly) ECTextStyle *declarationStyle;
@property (nonatomic, strong, readonly) ECTextStyle *preprocessingStyle;
@end

@implementation ACFileDocument

@synthesize contentString = _contentString;
@synthesize codeUnit = _codeUnit;
@synthesize defaultTextStyle = _defaultTextStyle, keywordStyle = _keywordStyle, commentStyle = _commentStyle, referenceStyle = _referenceStyle, literalStyle = _literalStyle, declarationStyle = _declarationStyle, preprocessingStyle = _preprocessingStyle;

- (void)setContentString:(NSString *)contentString
{
    if (contentString == _contentString)
        return;
    [self willChangeValueForKey:@"contentString"];
    _contentString = contentString;
    [self updateChangeCount:UIDocumentChangeDone];
    [self didChangeValueForKey:@"contentString"];
}

- (ECTextStyle *)defaultTextStyle
{
    if (!_defaultTextStyle)
        _defaultTextStyle = [ECTextStyle textStyleWithName:@"default" font:[UIFont fontWithName:@"Inconsolata-dz" size:15] color:nil];
    return _defaultTextStyle;
}

- (ECTextStyle *)keywordStyle
{
    if (!_keywordStyle)
        _keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" font:nil color:[UIColor colorWithRed:200.0/255.0 green:0.0/255.0 blue:151.0/255.0 alpha:1]];
    return _keywordStyle;
}

- (ECTextStyle *)commentStyle
{
    if (!_commentStyle)
        _commentStyle = [ECTextStyle textStyleWithName:@"Comment" font:nil color:[UIColor colorWithRed:0.0/255.0 green:133.0/255.0 blue:13.0/255.0 alpha:1]];
    return _commentStyle;
}

- (ECTextStyle *)referenceStyle
{
    if (!_referenceStyle)
        _referenceStyle = [ECTextStyle textStyleWithName:@"Reference" font:nil color:[UIColor purpleColor]];
    return _referenceStyle;
}

- (ECTextStyle *)literalStyle
{
    if (!_literalStyle)
        _literalStyle = [ECTextStyle textStyleWithName:@"Strings" font:nil color:[UIColor colorWithRed:222.0/255.0 green:19.0/255.0 blue:0.0/255.0 alpha:1]];
    return _literalStyle;
}

- (ECTextStyle *)declarationStyle
{
    if (!_declarationStyle)
        _declarationStyle = [ECTextStyle textStyleWithName:@"Declaration" font:nil color:[UIColor colorWithRed:57.0/255.0 green:118.0/255.0 blue:126.0/255.0 alpha:1]];
    return _declarationStyle;
}

- (ECTextStyle *)preprocessingStyle
{
    if (!_preprocessingStyle)
        _preprocessingStyle = [ECTextStyle textStyleWithName:@"Preprocessor Statements" font:nil color:[UIColor colorWithRed:115.0/255.0 green:66.0/255.0 blue:33.0/255.0 alpha:1]];
    return _preprocessingStyle;
}

#pragma mark - UIDocument methods

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super openWithCompletionHandler:^(BOOL success){
        if (success)
        {
            ECCodeIndex *codeIndex = [[ECCodeIndex alloc] init];
            self.codeUnit = [codeIndex unitWithFileURL:self.fileURL];
        }
        completionHandler(success);
    }];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super closeWithCompletionHandler:^(BOOL success){
        if (success)
            self.codeUnit = nil;
        completionHandler(success);
    }];
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [self.contentString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self.contentString = [NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:NULL];
    return YES;
}

#pragma mark - Text Renderer DataSource Methods

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString
{
    NSUInteger lineIndex, stringLength = [self.contentString length];
    NSRange stringRange = NSMakeRange(0, 0);
    
    // Calculate string range location for query line range location
    for (lineIndex = 0; lineIndex < lineRange->location; ++lineIndex)
        stringRange.location = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ stringRange.location, 0 }]);
    
    if (stringRange.location >= stringLength)
        return nil;
    
    // Calculate string range lenght for query line range length
    stringRange.length = stringRange.location;
    for (lineIndex = 0; lineIndex < lineRange->length && stringRange.length < stringLength; ++lineIndex)
        stringRange.length = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ stringRange.length, 0 }]);
    stringRange.length -= stringRange.location;
    
    // Assign return read count of lines
    lineRange->length = lineIndex;
    
    // Indicate if at end of string
    *endOfString = NSMaxRange(stringRange) >= stringLength;
    
    // Preparing result
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[self.contentString substringWithRange:stringRange] attributes:self.defaultTextStyle.CTAttributes];
    
    for (ECCodeToken *token in [self.codeUnit tokensInRange:stringRange withCursors:YES])
    {
        switch (token.kind)
        {
            case ECCodeTokenKindKeyword:
                [result addAttributes:self.keywordStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                break;
                
            case ECCodeTokenKindComment:
                [result addAttributes:self.commentStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                break;
                
            case ECCodeTokenKindLiteral:
                [result addAttributes:self.literalStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                break;
                
            default:
            {
                if (token.cursor.kind >= ECCodeCursorKindFirstDecl && token.cursor.kind <= ECCodeCursorKindLastDecl)
                    [result addAttributes:self.declarationStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                else if (token.cursor.kind >= ECCodeCursorKindFirstRef && token.cursor.kind <= ECCodeCursorKindLastRef)
                    [result addAttributes:self.referenceStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                else if (token.cursor.kind >= ECCodeCursorKindFirstPreprocessing && token.cursor.kind <= ECCodeCursorKindLastPreprocessing)
                    [result addAttributes:self.preprocessingStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                break;
            }
        }
    }
    
    // Append tailing new line
    if (*endOfString) 
    {
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n" attributes:self.defaultTextStyle.CTAttributes];
        [result appendAttributedString:newLine];
    }
    
    return result;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)textLength
{
    return [self.contentString length];
}

- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range
{
    return [self.contentString substringWithRange:range];
}

- (BOOL)codeView:(ECCodeViewBase *)codeView canEditTextInRange:(NSRange)range
{
    return YES;
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    NSUInteger strLength = [self.contentString length];
    if (range.location + range.length > strLength) 
        return;
    
    if (range.length == strLength) 
    {
        self.contentString = commitString;
        [codeView updateAllText];
    }
    else
    {
        NSUInteger index = 0;
        NSRange fromLineRange = NSMakeRange(0, 0);
        NSUInteger toLineCount = 0, limit;
        // From line location
        for (index = 0; index < range.location; ++fromLineRange.location)
            index = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ index, 0 }]);
        if (fromLineRange.location)
            fromLineRange.location--;
        // From line count
        limit = NSMaxRange(range);
        for (index = range.location; index <= limit; ++fromLineRange.length)
            index = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ index, 0 }]);
        // To line count
        limit = range.location + [commitString length];
        for (index = range.location; index <= limit; ++toLineCount)
            index = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ index, 0 }]);
        
        if ([commitString length])
        {
            NSMutableString *mutableContentString = [NSMutableString stringWithString:self.contentString];
            [mutableContentString replaceCharactersInRange:range withString:commitString];
            self.contentString = mutableContentString;
        }
        else
        {
            NSMutableString *mutableContentString = [NSMutableString stringWithString:self.contentString];
            [mutableContentString deleteCharactersInRange:range];
            self.contentString = mutableContentString;
        }
        
        [codeView updateTextInLineRange:fromLineRange toLineRange:(NSRange){ fromLineRange.location, toLineCount }];
    }
}

@end
