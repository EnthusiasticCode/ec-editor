//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 Enthusiastic Code. All rights reserved.
//

#import "ECCodeView.h"

#import "OUEFTextRange.h"
#import "ECCodeViewCompletion.h"

@implementation ECCodeView


@synthesize completionProviders = _completionProviders;

- (NSArray *)completionProviders
{
    if (!_completionProviders)
        _completionProviders = [[NSArray alloc] init];
    return _completionProviders;
}

@synthesize syntaxCheckers = _syntaxCheckers;

- (NSArray *)syntaxCheckers
{
    if (!_syntaxCheckers)
        _syntaxCheckers = [[NSArray alloc] init];
    return _syntaxCheckers;
}
@synthesize completionPopover = _completionPopover;

- (ECPopoverTableController *)completionPopover
{
    if (!_completionPopover)
    {
        _completionPopover = [[ECPopoverTableController alloc] init];
        _completionPopover.viewToPresentIn = self;
    }   
    return _completionPopover;
}

- (void)awakeFromNib
{
    [self addObserver:self forKeyPath:@"selectedTextRange" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"attributedText" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)dealloc {
    [_completionProviders release];
    [_syntaxCheckers release];
    self.completionPopover = nil;
    [super dealloc];
}

- (void) addCompletionProvider:(id<ECCodeViewCompletionProvider>)completionProvider
{
    NSArray *oldCompletionProviders = _completionProviders;
    _completionProviders = [self.completionProviders arrayByAddingObject:completionProvider];
    [_completionProviders retain];
    [oldCompletionProviders release];
}

- (void) addSyntaxChecker:(id<ECCodeViewSyntaxChecker>)syntaxChecker
{
    NSArray *oldSyntaxCheckers = _syntaxCheckers;
    _syntaxCheckers = [self.syntaxCheckers arrayByAddingObject:syntaxChecker];
    [_syntaxCheckers retain];
    [oldSyntaxCheckers release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self showCompletions];
}

- (void)showCompletions
{
    NSRange selectedRange = [(OUEFTextRange *)[self selectedTextRange] range];
    NSMutableArray *possibleCompletions = [[NSMutableArray alloc] init];
    for (id<ECCodeViewCompletionProvider>completionProvider in _completionProviders)
    {
        [possibleCompletions addObjectsFromArray:[completionProvider completionsWithSelection:selectedRange inString:[self.attributedText string]]];
    }
    NSMutableArray *completionLabels = [[NSMutableArray alloc] initWithCapacity:[possibleCompletions count]];
    for (ECCodeViewCompletion *completion in possibleCompletions)
    {
        [completionLabels addObject:completion.label];
    }
    
    self.completionPopover.didSelectRow =
        ^ void (int row)
        {
            NSRange replacementRange = [[possibleCompletions objectAtIndex:row] replacementRange];
            UITextRange *replacementTextRange = (UITextRange *)[[OUEFTextRange alloc] initWithRange:replacementRange generation:0];
            NSString *replacementString = [[possibleCompletions objectAtIndex:row] string];
            [self replaceRange:replacementTextRange withText:replacementString];
            [replacementTextRange release];
        };
    self.completionPopover.popoverRect = [self firstRectForRange:[self selectedTextRange]];
    self.completionPopover.strings = completionLabels;
    
    [completionLabels release];
    [possibleCompletions release];
}

@end
