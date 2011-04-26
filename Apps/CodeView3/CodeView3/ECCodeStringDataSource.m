//
//  ECCodeStringDataSource.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 23/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeStringDataSource.h"
#import "ECCodeView4.h"

@interface ECCodeStringDataSource () {
@private
    NSMutableAttributedString *string;
}

- (void)updateLinesLenghts;

@end

@implementation ECCodeStringDataSource

@synthesize defaultTextStyle;

- (NSString *)string
{
    return [string string];
}

- (void)setString:(NSString *)aString
{
    [string release];
    string = [[NSMutableAttributedString alloc] initWithString:aString attributes:defaultTextStyle.CTAttributes];
    [self updateLinesLenghts];
}

#pragma makr NSObject Methods

- (id)init {
    if ((self = [super init])) 
    {
        defaultTextStyle = [ECTextStyle textStyleWithName:@"default" font:[UIFont fontWithName:@"Courier New" size:12] color:nil];
    }
    return self;
}

- (void)dealloc
{
    [string release];
    [super dealloc];
}

#pragma mark Text Renderer DataSource Methods

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange
{
    NSString *str = [string string];
    
    __block NSRange stringRange = NSMakeRange(0, 0), lineStringRange = NSMakeRange(0, 0);
    __block NSUInteger lineIndex = 0, lineCount = 0;
    [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        lineStringRange = [str lineRangeForRange:(NSRange){ lineStringRange.location, [line length] }];
        if (lineIndex >= lineRange->location) 
        {
            if (lineRange->length && lineCount >= lineRange->length) 
            {
                *stop = YES;
            }
            else
            {
                stringRange.length += lineStringRange.length;
                lineCount++;
            }
        }
        else
        {
            stringRange.location += lineStringRange.length;
        }
        lineStringRange.location += lineStringRange.length;
        lineIndex++;
    }];
    
    if (stringRange.location + stringRange.length == [str length]) 
    {
        return string;
    }
    
    return [string attributedSubstringFromRange:stringRange];
}

- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength
{
    __block NSUInteger count = 0;
    [[string string] enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        count += ceilf([line length] / maximumLineLength);
    }];
    return count;
}

#pragma mark Code View DataSource Methods

- (NSUInteger)textLength
{
    return [string length];
}

- (NSString *)codeView:(ECCodeView4 *)codeView stringInRange:(NSRange)range
{
    return [[string string] substringWithRange:range];
}

- (BOOL)codeView:(ECCodeView4 *)codeView canEditTextInRange:(NSRange)range
{
    return YES;
}

- (void)codeView:(ECCodeView4 *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    NSString *str = [string string];
    NSUInteger strLength = [str length];
    if (range.location + range.length > strLength) 
        return;
    
    if (range.length == strLength) 
    {
        self.string = commitString;
        [codeView updateAllText];
    }
    else
    {
        NSUInteger index = 0;
        NSRange fromLineRange = NSMakeRange(0, 0);
        NSUInteger toLineCount = 0, limit;
        for (index = 0; index < range.location; ++fromLineRange.location)
            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
        limit = NSMaxRange(range);
        for (index = range.location; index < limit; ++fromLineRange.length)
            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
        limit = range.location + [commitString length];
        for (index = range.location; index < limit; ++toLineCount)
            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
        
        [string beginEditing];
        if (!commitString || [commitString length] == 0)
            [string deleteCharactersInRange:range];
        else
            [string replaceCharactersInRange:range withString:commitString];
        [string endEditing];
        
        [codeView updateTextInLineRange:fromLineRange toLineRange:(NSRange){ fromLineRange.location, toLineCount }];
    }
}

@end
