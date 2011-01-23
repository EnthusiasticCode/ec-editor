//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 Enthusiastic Code. All rights reserved.
//

#import "ECCodeView.h"

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

- (void)showCompletions
{
    NSMutableArray *possibleCompletions = [[NSMutableArray alloc] init];
    for (id<ECCodeViewCompletionProvider>completionProvider in _completionProviders)
    {
        [possibleCompletions addObjectsFromArray:[completionProvider completionsWithSelection:self.selectedRange inString:self.text]];
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
            NSString *replacementString = [[possibleCompletions objectAtIndex:row] string];
            self.text = [self.text stringByReplacingCharactersInRange:replacementRange withString:replacementString];
        };
//    self.completionPopover.popoverRect = [self firstRectForRange:[self selectedRange]];
    self.completionPopover.strings = completionLabels;
    
    [completionLabels release];
    [possibleCompletions release];
}

@end
