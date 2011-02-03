//
//  ECCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
#import "ECClangCodeIndexer.h"

@implementation ECCodeIndexer

@synthesize source = _source;
@synthesize delegate = _delegate;
@synthesize diagnostics = _diagnostics;

- (void)dealloc
{
    self.source = nil;
    self.delegate = nil;
    [_diagnostics dealloc];
    [super dealloc];
}

- (id)init
{
    [self release];
    self = [[ECClangCodeIndexer alloc] init];
    return self;
}

- (NSRange)completionRange
{
    if (!self.delegate)
        return NSMakeRange(NSNotFound, 0);
    
    NSString *string = [self.delegate indexedTextBuffer];
    NSRange selection = [self.delegate indexedTextSelection];
    
    if (!string || selection.length || !selection.location) //range of text is selected or caret is at beginning of file
        return NSMakeRange(NSNotFound, 0);
    
    NSUInteger precedingCharacterIndex = selection.location - 1;
    NSUInteger precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
    
    if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
        return NSMakeRange(NSNotFound, 0);
    
    while (precedingCharacterIndex)
    {
        if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
        {
            NSUInteger length = selection.location - (precedingCharacterIndex + 1);
            if (length)
                return NSMakeRange(precedingCharacterIndex + 1, length);
        }
        precedingCharacterIndex--;
        precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
    }
    return NSMakeRange(0, selection.location); //if control has reached this point all character between the caret and the beginning of file are letters
}

- (NSArray *)completions
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

- (NSArray *)tokensForRange:(NSRange)range
{
    return nil;
}

- (NSArray *)tokens
{
    if (!self.delegate)
        return nil;
    return [self tokensForRange:NSMakeRange(0, [[self.delegate indexedTextBuffer] length])];
}

@end
