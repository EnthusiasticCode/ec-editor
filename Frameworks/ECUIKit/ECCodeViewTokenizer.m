//
//  ECCodeViewTokenizer.m
//  CodeView
//
//  Created by Nicola Peduzzi on 07/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewTokenizer.h"
#import "ECCodeView.h"
#import "ECTextPosition.h"
#import "ECTextRange.h"

static inline BOOL UITextDirectionIsForward(UITextDirection direction)
{
    // TODO change for UITextLayoutDirectionUp
    return !(direction % 2);
}

static inline UITextDirection UITextDirectionInverse(UITextDirection direction)
{
    return direction % 2 ? direction - 1 : direction + 1;
}

static inline NSStringEnumerationOptions NSStringEnumerationOptionsForGranularity(UITextGranularity granularity)
{
    switch (granularity) {
        case UITextGranularityCharacter:
            return NSStringEnumerationByComposedCharacterSequences;
        case UITextGranularityLine:
            return NSStringEnumerationByLines;
        case UITextGranularityParagraph:
            return NSStringEnumerationByParagraphs;
        case UITextGranularitySentence:
            return NSStringEnumerationBySentences;
        case UITextGranularityWord:
            return NSStringEnumerationByWords;
        default:
            return 0;
    }
}

@implementation ECCodeViewTokenizer {
    ECCodeView *codeView;
}


- (id)initWithCodeView:(ECCodeView *)aCodeView
{
    if ((self = [super initWithTextInput:aCodeView]))
    {
        codeView = aCodeView;
    }
    return self;
}

#pragma mark - UITextInputTokenizer Protocol Implementation

- (BOOL)isPosition:(UITextPosition *)position atBoundary:(UITextGranularity)granularity inDirection:(UITextDirection)direction
{
//    NSUInteger pos = [(ECTextPosition *)position index];
    return [super isPosition:position atBoundary:granularity inDirection:direction];
}

- (BOOL)isPosition:(UITextPosition *)position withinTextUnit:(UITextGranularity)granularity inDirection:(UITextDirection)direction
{
    return [super isPosition:position withinTextUnit:granularity inDirection:direction];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position toBoundary:(UITextGranularity)granularity inDirection:(UITextDirection)direction
{
    return [super positionFromPosition:position toBoundary:granularity inDirection:direction];
}

- (UITextRange *)rangeEnclosingPosition:(UITextPosition *)position withGranularity:(UITextGranularity)granularity inDirection:(UITextDirection)direction
{
    UITextDirection oppositeDirection = UITextDirectionInverse(direction);
    position = [self positionFromPosition:position toBoundary:granularity inDirection:oppositeDirection];
    
    // TODO how much to get?
    NSRange requiredRange = NSMakeRange([(ECTextPosition *)position index], 100);
    NSString *text = [codeView.datasource codeView:codeView stringInRange:requiredRange];
    
    NSStringEnumerationOptions options = NSStringEnumerationOptionsForGranularity(granularity);
    if (!UITextDirectionIsForward(direction))
        options |= NSStringEnumerationReverse;
    [text enumerateSubstringsInRange:NSMakeRange(0, [text length]) options:options usingBlock:^(NSString *__strong substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        
    }];
    
    return [super rangeEnclosingPosition:position withGranularity:granularity inDirection:direction];
}

@end
