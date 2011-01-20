//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeIndexer.h"

#import "ECCodeViewCompletion.h"

@implementation ECClangCodeIndexer


@synthesize textChecker = _textChecker;

- (UITextChecker *)textChecker
{
    if (!_textChecker)
        _textChecker = [[UITextChecker alloc] init];
    return _textChecker;
}

- (void)dealloc
{
    self.textChecker = nil;
    [super dealloc];
}

- (NSRange)completionRangeWithSelection:(NSRange)selection inString:(NSString *)string
{
    if (selection.length || !selection.location) return NSMakeRange(NSNotFound, 0); //range of text is selected or caret is at beginning of file
    
    NSUInteger precedingCharacterIndex = selection.location - 1;
    NSUInteger precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
    
    if (precedingCharacter < 65 || precedingCharacter > 122) return NSMakeRange(NSNotFound, 0); //character is not a letter
    
    while (precedingCharacterIndex)
    {
        if (precedingCharacter < 65 || precedingCharacter > 122) //character is not a letter
        {
            NSUInteger length = selection.location - (precedingCharacterIndex + 1);
            if (length) return NSMakeRange(precedingCharacterIndex + 1, length);
        }
        precedingCharacterIndex--;
        precedingCharacter = [string characterAtIndex:precedingCharacterIndex];
    }
    return NSMakeRange(0, selection.location); //if control has reached this point all character between the caret and the beginning of file are letters
}

- (NSArray *)completionsWithSelection:(NSRange)selection inString:(NSString *)string;
{    
    NSRange replacementRange = [self completionRangeWithSelection:selection inString:string];
    NSArray *guesses = [self.textChecker guessesForWordRange:replacementRange inString:string language:@"en_US"];
    NSMutableArray *completions = [[[NSMutableArray alloc] init] autorelease];
    for (NSString *guess in guesses)
    {
        [completions addObject:[ECCodeViewCompletion completionWithReplacementRange:replacementRange label:guess string:[guess stringByAppendingString:@" "]]];
    }
    return completions;
}

@end
