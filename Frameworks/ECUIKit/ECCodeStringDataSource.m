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
}

#pragma makr NSObject Methods

- (id)init {
    if ((self = [super init])) 
    {
        defaultTextStyle = [[ECTextStyle textStyleWithName:@"default" font:[UIFont fontWithName:@"Courier New" size:15] color:nil] retain];
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
    NSUInteger lineIndex, stringLength = [str length];
    NSRange stringRange = NSMakeRange(0, 0);

    // Calculate string range location for query line range location
    for (lineIndex = 0; lineIndex < lineRange->location; ++lineIndex)
        stringRange.location = NSMaxRange([str lineRangeForRange:(NSRange){ stringRange.location, 0 }]);
    
    if (stringRange.location >= stringLength)
        return nil;
    
    // Calculate string range lenght for query line range length
    stringRange.length = stringRange.location;
    for (lineIndex = 0; lineIndex < lineRange->length && stringRange.length < stringLength; ++lineIndex)
        stringRange.length = NSMaxRange([str lineRangeForRange:(NSRange){ stringRange.length, 0 }]);
    stringRange.length -= stringRange.location;

    // Assign return read count of lines
    lineRange->length = lineIndex;
    
    // Return requested substring
    if (stringRange.length == stringLength) 
        return string;
    
    return [string attributedSubstringFromRange:stringRange];
}

- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength
{
    CGFloat max = maximumLineLength;
    __block NSUInteger count = 0;
    [[string string] enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        count += ceilf((float)[line length] / max);
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

#pragma mark Text Styling Methods

- (void)addTextStyle:(ECTextStyle *)textStyle toStringRange:(NSRange)range
{
    if (!textStyle || NSMaxRange(range) > [string length])
        return;
    
    [string addAttributes:textStyle.CTAttributes range:range];
}

- (void)removeTextStyle:(ECTextStyle *)textStyle fromStringRange:(NSRange)range
{
    if (!textStyle || NSMaxRange(range) > [string length])
        return;
    
    for (NSString *attr in textStyle.CTAttributes)
        [string removeAttribute:attr range:range];
}

- (void)removeAllTextStylesFromRange:(NSRange)range
{
    if (NSMaxRange(range) > [string length])
        return;
    
    [string setAttributes:defaultTextStyle.CTAttributes range:range];
}

- (void)removeAllTextStyles
{
    [string setAttributes:defaultTextStyle.CTAttributes range:(NSRange){0, [string length]}];
}

@end
