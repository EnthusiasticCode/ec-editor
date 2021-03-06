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
}

@synthesize defaultTextStyle;

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
    }
    return self;
}

#pragma mark Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(ECTextRenderer *)sender
{
    return [string length];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    if (string == nil)
        return nil;
    
    // Preparing result
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[string.string substringWithRange:stringRange] attributes:defaultTextStyle.CTAttributes];
    
    // Append tailing new line
    if (NSMaxRange(stringRange) == [string length]) 
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
//        NSUInteger index = 0;
//        NSRange fromLineRange = NSMakeRange(0, 0);
//        NSUInteger toLineCount = 0, limit;
//        // From line location
//        for (index = 0; index < range.location; ++fromLineRange.location)
//            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
//        if (fromLineRange.location)
//            fromLineRange.location--;
//        // From line count
//        limit = NSMaxRange(range);
//        for (index = range.location; index <= limit; ++fromLineRange.length)
//            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
//        // To line count
//        limit = range.location + [commitString length];
//        for (index = range.location; index <= limit; ++toLineCount)
//            index = NSMaxRange([str lineRangeForRange:(NSRange){ index, 0 }]);
        
        [string beginEditing];
        if (!commitString || [commitString length] == 0)
            [string deleteCharactersInRange:range];
        else
            [string replaceCharactersInRange:range withString:commitString];
        [string endEditing];
        
//        [codeView updateTextInLineRange:fromLineRange toLineRange:(NSRange){ fromLineRange.location, toLineCount }];
        [codeView updateAllText];
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

@end
