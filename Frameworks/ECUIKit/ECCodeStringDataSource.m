//
//  ECCodeStringDataSource.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 23/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeStringDataSource.h"
#import "ECCodeViewBase.h"


@implementation ECCodeStringDataSource {
@private
    NSMutableAttributedString *string;
    
    NSMutableDictionary *stylingBlocks;
    NSMutableDictionary *overlayPasses;
    NSMutableDictionary *underlayPasses;
}

@synthesize textInsets, defaultTextStyle;

- (NSString *)string
{
    return [string string];
}

- (void)setString:(NSString *)aString
{
    string = [[NSMutableAttributedString alloc] initWithString:aString attributes:defaultTextStyle.CTAttributes];
}

#pragma makr NSObject Methods

- (id)init {
    if ((self = [super init])) 
    {
        defaultTextStyle = [ECTextStyle textStyleWithName:@"default" font:[UIFont fontWithName:@"Inconsolata-dz" size:15] color:nil];
        textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

#pragma mark Text Renderer DataSource Methods

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString
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
    
    // Indicate if at end of string
    *endOfString = NSMaxRange(stringRange) >= stringLength;
    
    // Preparing result
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[string.string substringWithRange:stringRange] attributes:defaultTextStyle.CTAttributes];
    
    // Append tailing new line
    if (*endOfString) 
    {
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n" attributes:defaultTextStyle.CTAttributes];
        [result appendAttributedString:newLine];
    }
    
    // Apply styling blocks
    for (ECCodeStringDataSourceStylingBlock stylingBlock in [stylingBlocks allValues]) {
        stylingBlock(result, stringRange);
    }
    
    return result;
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

- (UIEdgeInsets)textInsetsForTextRenderer:(ECTextRenderer *)sender
{
    return textInsets;
}

- (NSArray *)underlayPassesForTextRenderer:(ECTextRenderer *)sender
{
    return [underlayPasses allValues];
}


- (NSArray *)overlayPassesForTextRenderer:(ECTextRenderer *)sender
{
    return [overlayPasses allValues];
}

#pragma mark Code View DataSource Methods

- (NSUInteger)textLength
{
    return [string length];
}

- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range
{
    return [[string string] substringWithRange:range];
}

- (BOOL)codeView:(ECCodeViewBase *)codeView canEditTextInRange:(NSRange)range
{
    return YES;
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
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
        // From line location
        for (index = 0; index < range.location; ++fromLineRange.location)
            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
        if (fromLineRange.location)
            fromLineRange.location--;
        // From line count
        limit = NSMaxRange(range);
        for (index = range.location; index <= limit; ++fromLineRange.length)
            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
        // To line count
        limit = range.location + [commitString length];
        for (index = range.location; index <= limit; ++toLineCount)
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

#pragma mark - Managing Styling Blocks

- (void)addStylingBlock:(ECCodeStringDataSourceStylingBlock)stylingBlock forKey:(NSString *)stylingKey
{
    ECASSERT(stylingBlock);
    
    if (!stylingBlocks)
        stylingBlocks = [NSMutableDictionary new];
    
    [stylingBlocks setObject:[stylingBlock copy] forKey:stylingKey];
}

- (void)removeStylingBlockForKey:(NSString *)stylingKey
{
    [stylingBlocks removeObjectForKey:stylingKey];
}

- (void)addPassLayerBlock:(ECTextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey
{
    if (isUnderlay)
    {
        if (!underlayPasses)
            underlayPasses = [NSMutableDictionary new];
        [underlayPasses setObject:[block copy] forKey:passKey];
    }
    else
    {
        if (!overlayPasses)
            overlayPasses = [NSMutableDictionary new];
        [overlayPasses setObject:[block copy] forKey:passKey];        
    }
}

- (void)removePassLayerForKey:(NSString *)passKey
{
    [underlayPasses removeObjectForKey:passKey];
    [overlayPasses removeObjectForKey:passKey];
}

@end
