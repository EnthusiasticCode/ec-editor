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

@implementation ECCodeView


@synthesize autoCompletionTokens = _autoCompletionTokens;

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

- (CompletionListController *)completionList
{
    if (!_completionList)
    {
        _completionList = [[CompletionListController alloc] initWithStyle:UITableViewStylePlain];
        _completionList.delegate = self;
    }   
    return _completionList;
}

- (UIPopoverController *)completionListPopover
{
    if (!_completionListPopover)
        _completionListPopover = [[UIPopoverController alloc] initWithContentViewController:[self completionList]];
    _completionListPopover.delegate = (id)self;
    return _completionListPopover;
}

- (void)awakeFromNib
{
    [self addObserver:self forKeyPath:@"selectedTextRange" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"attributedText" options:NSKeyValueObservingOptionNew context:NULL];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserver:self forKeyPath:@"selectedTextRange" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"attributedText" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc {
    [_completionListPopover release];
    [_completionList release];
    [_autoCompletionTokens release];
    [_textChecker release];
    [super dealloc];
}

#pragma mark -
#pragma KVO

// Omnigroup didn't bother adding willChangeValueForKey: and didChangeValueForKey: in their beforeMutate and notifyAfterMutate static functions, so we added empty methods we can subclass and do it ourselves

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    BOOL automatic = NO;
    
    if ([theKey isEqualToString:@"attributedText"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

- (void)beforeMutate
{
    [self willChangeValueForKey:@"attributedText"];
}

- (void)notifyAfterMutate
{
    [self didChangeValueForKey:@"attributedText"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self showCompletions];
}

#pragma mark -
#pragma mark Autocompletion

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

- (void)showCompletions
{
    NSArray *possibleCompletions = [self.textChecker guessesForWordRange:[self completionRange] inString:[self.attributedText string] language:@"en_US"];
    if (![possibleCompletions count])
    {
        [_completionListPopover dismissPopoverAnimated:YES];
    }
    else
    {
        self.completionList.resultsList = possibleCompletions;
        self.completionListPopover.popoverContentSize = CGSizeMake(150.0, 400.0);
        
        CGRect pRect = [self firstRectForRange:(UITextRange *)[[OUEFTextRange alloc] initWithRange:self.completionRange generation:0]];
        [self.completionListPopover presentPopoverFromRect:pRect inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)completeWithString:(NSString *)string
{
    UITextRange *replacementRange = (UITextRange *)[[OUEFTextRange alloc] initWithRange:[self completionRange] generation:0];
    NSString *replacementString = [string stringByAppendingString:@" "];
    [self replaceRange:replacementRange withText:replacementString];
}

@end
