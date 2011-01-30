//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 Enthusiastic Code. All rights reserved.
//

#import "ECCodeView.h"

#import "ECCodeCompletion.h"

@implementation ECCodeView


@synthesize codeIndexers = _codeIndexers;

- (NSArray *)codeIndexers
{
    if (!_codeIndexers)
        _codeIndexers = [[NSArray alloc] init];
    return _codeIndexers;
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
    [_codeIndexers release];
    self.completionPopover = nil;
    [super dealloc];
}

- (void) addCodeIndexer:(id<ECCodeIndexer>)codeIndexer
{
    NSArray *oldCodeIndexers = _codeIndexers;
    _codeIndexers = [self.codeIndexers arrayByAddingObject:codeIndexer];
    [_codeIndexers retain];
    [oldCodeIndexers release];
}

- (void)showCompletions
{
    NSMutableArray *possibleCompletions = [[NSMutableArray alloc] init];
    for (id<ECCodeIndexer>codeIndexer in _codeIndexers)
    {
        [possibleCompletions addObjectsFromArray:[codeIndexer completionsWithSelection:self.selectedRange inString:self.text]];
    }
    NSMutableArray *completionLabels = [[NSMutableArray alloc] initWithCapacity:[possibleCompletions count]];
    for (ECCodeCompletion *completion in possibleCompletions)
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
