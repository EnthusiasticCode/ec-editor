//
//  ACCodeIndexerDataSource.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeIndexerDataSource.h"
#import "ECTextStyle.h"

#import "ECCodeUnit.h"
#import "ECCodeToken.h"
#import "ECCodeCursor.h"

#import "ACCompletionController.h"

#define LINE_NUMBERS_SPACE_WIDTH 30

@implementation ACCodeIndexerDataSource {
    ACCompletionController *completionController;
}

static NSRange intersectionOfRangeRelativeToRange(NSRange range, NSRange inRange)
{
    NSRange intersectionRange = NSIntersectionRange(range, inRange);
    intersectionRange.location -= inRange.location;
    return intersectionRange;
}

@synthesize codeUnit;
@synthesize showLineNumbers;
@synthesize keywordStyle, commentStyle, referenceStyle, literalStyle, declarationStyle, preprocessingStyle;

- (void)setShowLineNumbers:(BOOL)value
{
    if (showLineNumbers == value)
        return;
    
    showLineNumbers = value;
    
    static NSString *lineNumberPassKey = @"LineNumbersUnderlayPass";
    if (showLineNumbers)
    {
        // TODO make a property
        static UIFont *lineNumersFont = nil;
        if (!lineNumersFont)
            lineNumersFont = [UIFont fontWithName:@"Helvetica" size:12];
        UIColor *lineNumbersColor = [UIColor colorWithWhite:0.5 alpha:1];
        
        __block NSUInteger lastLine = NSUIntegerMax;
        [self addPassLayerBlock:^(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
            // Rendering line number
            if (lastLine != lineNumber)
            {
                // TODO get this more efficient. possibly by creating line numbers with preallocated characters.
                NSString *lineNumberString = [NSString stringWithFormat:@"%u", lineNumber + 1];
                CGSize lineNumberStringSize = [lineNumberString sizeWithFont:lineNumersFont];
                
                CGContextSelectFont(context, lineNumersFont.fontName.UTF8String, lineNumersFont.pointSize, kCGEncodingMacRoman);
                CGContextSetTextDrawingMode(context, kCGTextFill);
                CGContextSetFillColorWithColor(context, lineNumbersColor.CGColor);

                CGContextShowTextAtPoint(context, -lineBounds.origin.x + LINE_NUMBERS_SPACE_WIDTH- lineNumberStringSize.width, -lineNumberStringSize.height + (lineBounds.size.height - lineNumberStringSize.height) / 2, lineNumberString.UTF8String, [lineNumberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
            }

            lastLine = lineNumber;
        } underText:YES forKey:lineNumberPassKey];
    }
    else
    {
        [self removePassLayerForKey:lineNumberPassKey];
    }
}

- (id)init
{
    if ((self = [super init]))
    {
        keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" font:nil color:[UIColor blueColor]];
        commentStyle = [ECTextStyle textStyleWithName:@"Comment" font:nil color:[UIColor greenColor]];
        referenceStyle = [ECTextStyle textStyleWithName:@"Reference" font:nil color:[UIColor purpleColor]];
        literalStyle = [ECTextStyle textStyleWithName:@"Literal" font:nil color:[UIColor redColor]];
        declarationStyle = [ECTextStyle textStyleWithName:@"Declaration" font:nil color:[UIColor brownColor]];
        preprocessingStyle = [ECTextStyle textStyleWithName:@"Preprocessing" font:nil color:[UIColor orangeColor]];
        
        __weak ACCodeIndexerDataSource *this = self;
        [self addStylingBlock:^(NSMutableAttributedString *string, NSRange stringRange)
        {
            for (ECCodeToken *token in [this->codeUnit tokensInRange:stringRange withCursors:YES])
            {
                switch (token.kind)
                {
                    case ECCodeTokenKindKeyword:
                        [string addAttributes:this->keywordStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                        
                    case ECCodeTokenKindComment:
                        [string addAttributes:this->commentStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                        
                    case ECCodeTokenKindLiteral:
                        [string addAttributes:this->literalStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                        
                    default:
                    {
                        if (token.cursor.kind >= ECCodeCursorKindFirstDecl && token.cursor.kind <= ECCodeCursorKindLastDecl)
                            [string addAttributes:this->declarationStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        else if (token.cursor.kind >= ECCodeCursorKindFirstRef && token.cursor.kind <= ECCodeCursorKindLastRef)
                            [string addAttributes:this->referenceStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        else if (token.cursor.kind >= ECCodeCursorKindFirstPreprocessing && token.cursor.kind <= ECCodeCursorKindLastPreprocessing)
                            [string addAttributes:this->preprocessingStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                        break;
                    }
                }
            }
        } forKey:@"IndexerStylingBlock"];
    }
    return self;
}

//- (UIViewController *)codeView:(ECCodeView *)codeView viewControllerForCompletionAtTextInRange:(NSRange)range
//{
//    if (!completionController)
//    {
//        completionController = [ACCompletionController new];
//    }
//    
//    
//}

- (UIEdgeInsets)textInsetsForTextRenderer:(ECTextRenderer *)sender
{
    UIEdgeInsets textInsets = [super textInsetsForTextRenderer:sender];
    if (showLineNumbers)
        textInsets.left += LINE_NUMBERS_SPACE_WIDTH;
    return textInsets;
}

@end
