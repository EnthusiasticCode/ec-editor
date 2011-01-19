//
//  ECCodeViewController.m
//  edit
//
//  Created by Uri Baghin on 1/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewController.h"

#import "OUEFTextRange.h"


@implementation ECCodeViewController


@synthesize textChecker = _textChecker;

- (UITextChecker *)textChecker
{
    if (!_textChecker)
        _textChecker = [[UITextChecker alloc] init];
    return _textChecker;
}

@synthesize completionPopover = _completionPopover;

- (ECPopoverTableController *)completionPopover
{
    if (!_completionPopover)
    {
        _completionPopover = [[ECPopoverTableController alloc] init];
        _completionPopover.delegate = self;
        _completionPopover.viewToPresentIn = self.view;
    }   
    return _completionPopover;
}

#pragma mark -
#pragma mark Initializations and clean up

- (void)viewDidLoad
{
    [self.view addObserver:self forKeyPath:@"selectedTextRange" options:NSKeyValueObservingOptionNew context:NULL];
    [self.view addObserver:self forKeyPath:@"attributedText" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)dealloc
{
    self.completionPopover = nil;
    self.textChecker = nil;
    self.view = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self showCompletions];
}

#pragma mark -
#pragma mark Autocompletion

- (NSRange)completionRange
{
    NSRange selectedRange = [(OUEFTextRange *)[(ECCodeView *)self.view selectedTextRange] range];
    
    if (selectedRange.length || !selectedRange.location) return NSMakeRange(NSNotFound, 0); //range of text is selected or caret is at beginning of file
    
    NSUInteger precedingCharacterIndex = selectedRange.location - 1;
    NSUInteger precedingCharacter = [[((ECCodeView *)self.view).attributedText string] characterAtIndex:precedingCharacterIndex];
    
    if (precedingCharacter < 65 || precedingCharacter > 122) return NSMakeRange(NSNotFound, 0); //character is not a letter
    
    while (precedingCharacterIndex)
    {
        if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
        {
            NSUInteger length = selectedRange.location - (precedingCharacterIndex + 1);
            if (length) return NSMakeRange(precedingCharacterIndex + 1, length);
        }
        precedingCharacterIndex--;
        precedingCharacter = [[((ECCodeView *)self.view).attributedText string] characterAtIndex:precedingCharacterIndex];
    }
    return NSMakeRange(0, selectedRange.location); //if control has reached this point all character between the caret and the beginning of file are letters
}

- (void)showCompletions
{
    NSArray *possibleCompletions = [self.textChecker guessesForWordRange:[self completionRange] inString:[((ECCodeView *)self.view).attributedText string] language:@"en_US"];
    OUEFTextRange *completionRange = [[OUEFTextRange alloc] initWithRange:self.completionRange generation:0];
    self.completionPopover.popoverRect = [(ECCodeView *)self.view firstRectForRange:(UITextRange *)completionRange];
    self.completionPopover.strings = possibleCompletions;
    [completionRange release];
}

- (void)popoverTableDidSelectRowWithText:(NSString *)string
{
    UITextRange *replacementRange = (UITextRange *)[[OUEFTextRange alloc] initWithRange:[self completionRange] generation:0];
    NSString *replacementString = [string stringByAppendingString:@" "];
    [(ECCodeView *)self.view replaceRange:replacementRange withText:replacementString];
    [replacementRange release];
}

@end
