//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 Enthusiastic Code. All rights reserved.
//

#import "ECCodeView.h"
#import "OUEFTextPosition.h"
#import "OUEFTextRange.h"
#import "CompletionListController.h"

@implementation ECCodeView

@synthesize autoCompletionTokens=_autoCompletionTokens;
@synthesize textChecker=_textChecker;

- (NSArray *)autoCompletionTokens
{
    if (!_autoCompletionTokens)
        _autoCompletionTokens = [NSArray arrayWithObjects:@" ", @".", @")", nil];
    return _autoCompletionTokens;
}

- (UITextChecker *)textChecker
{
    if (!_textChecker)
        _textChecker = [[UITextChecker alloc] init];
    return _textChecker;
}

- (NSRange)completionRange
{
    NSRange selectedRange = [(OUEFTextRange *)[self selectedTextRange] range];
    
    if (selectedRange.length || !selectedRange.location) return NSMakeRange(NSNotFound, 0); //range of text is selected or caret is at beginning of file
    
    NSUInteger precedingCharacterIndex = selectedRange.location - 1;
    NSUInteger precedingCharacter = [[self.attributedText string] characterAtIndex:precedingCharacterIndex];
    
    if (precedingCharacter < 65 || precedingCharacter > 122) return NSMakeRange(NSNotFound, 0); //character is not a letter
    
    while (precedingCharacterIndex)
    {
        if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
        {
            NSUInteger length = selectedRange.location - (precedingCharacterIndex + 1);
            if (length) return NSMakeRange(precedingCharacterIndex + 1, length);
        }
        precedingCharacterIndex--;
        precedingCharacter = [[self.attributedText string] characterAtIndex:precedingCharacterIndex];
    }
    return NSMakeRange(0, selectedRange.location); //if control has reached this point all character between the caret and the beginning of file are letters
}

- (void)insertText:(NSString *)text
{
    // iPad simulator's Japanese input method likes to try to insert nil. I don't know why.
    if (!text)
        return;
    [super insertText:text];
    NSRange completionRange = [self completionRange];
    NSString *content = [self.attributedText string];
    NSArray *possibleCompletions = [self.textChecker guessesForWordRange:completionRange inString:content language:@"en_US"];
    NSLog(@"%@", possibleCompletions);
//    CGSize popOverSize = CGSizeMake(150.0, 400.0);
//    
//    CompletionListController *completionList = [[CompletionListController alloc] initWithStyle:UITableViewStylePlain];
//    completionList.resultsList = possibleCompletions;
//    UIPopoverController *completionListPopover = [[UIPopoverController alloc] initWithContentViewController:completionList];
//    completionListPopover.popoverContentSize = popOverSize;
//    completionListPopover.delegate = (id)self;
//    // rectForPartialWordRange: is a custom method
//    CGRect pRect = [self firstRectForRange:(UITextRange *)[[OUEFTextRange alloc] initWithRange:self.completionRange generation:0]];
//    [completionListPopover presentPopoverFromRect:pRect inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)dealloc {
    [_autoCompletionTokens release];
    [_textChecker release];
    [super dealloc];
}


@end
