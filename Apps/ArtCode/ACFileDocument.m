//
//  ACFileDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileDocument.h"
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/TMTheme.h>
#import <ECUIKit/ECTextStyle.h>

static NSRange intersectionOfRangeRelativeToRange(NSRange range, NSRange inRange)
{
    NSRange intersectionRange = NSIntersectionRange(range, inRange);
    intersectionRange.location -= inRange.location;
    return intersectionRange;
}

@interface ACFileDocument ()
@property (nonatomic, strong) NSString *contentString;
@property (nonatomic, strong) id<ECCodeParser>codeParser;
@property (nonatomic, strong, readonly) ECTextStyle *defaultTextStyle;
@end

@implementation ACFileDocument

@synthesize contentString = _contentString;
@synthesize codeParser = _codeParser;
@synthesize defaultTextStyle = _defaultTextStyle;
@synthesize theme = _theme;

- (void)setContentString:(NSString *)contentString
{
    if (contentString == _contentString)
        return;
    [self willChangeValueForKey:@"contentString"];
    _contentString = contentString;
    [self updateChangeCount:UIDocumentChangeDone];
    [self didChangeValueForKey:@"contentString"];
}

- (TMTheme *)theme
{
    if (!_theme)
        _theme = [TMTheme themeWithName:[[TMTheme themeNames] lastObject]];
    return _theme;
}

#pragma mark - UIDocument methods

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super openWithCompletionHandler:^(BOOL success){
        if (success)
        {
            ECCodeIndex *codeIndex = [[ECCodeIndex alloc] init];
            self.codeParser = [codeIndex codeUnitImplementingProtocol:@protocol(ECCodeParser) withFile:self.fileURL language:nil scope:nil];
        }
        completionHandler(success);
    }];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super closeWithCompletionHandler:^(BOOL success){
        if (success)
            self.codeParser = nil;
        completionHandler(success);
    }];
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [self.contentString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    self.contentString = [NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:NULL];
    return YES;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)textLength
{
    return [self.contentString length];
}

- (NSAttributedString *)codeView:(ECCodeViewBase *)codeView attributedStringInRange:(NSRange)stringRange
{
    // Preparing result
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[self.contentString substringWithRange:stringRange] attributes:self.defaultTextStyle.CTAttributes];
    
    [self.codeParser enumerateScopesInRange:stringRange usingBlock:^(NSArray *scopes, NSRange range, ECCodeScopeEnumerationStackChange change, BOOL *skipChildren, BOOL *cancel) {
        NSLog(@"%@", [scopes lastObject]);
    }];
        
    // Append tailing new line
    if (NSMaxRange(stringRange) == self.contentString.length) 
    {
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n" attributes:self.defaultTextStyle.CTAttributes];
        [result appendAttributedString:newLine];
    }
    
    return result;
}

- (BOOL)codeView:(ECCodeViewBase *)codeView canEditTextInRange:(NSRange)range
{
    return YES;
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    NSUInteger strLength = [self.contentString length];
    if (range.location + range.length > strLength) 
        return;
    
    if (range.length == strLength) 
    {
        self.contentString = commitString;
        [codeView updateAllText];
    }
    else
    {
        NSUInteger index = 0;
        NSRange fromLineRange = NSMakeRange(0, 0);
        NSUInteger toLineCount = 0, limit;
        // From line location
        for (index = 0; index < range.location; ++fromLineRange.location)
            index = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ index, 0 }]);
        if (fromLineRange.location)
            fromLineRange.location--;
        // From line count
        limit = NSMaxRange(range);
        for (index = range.location; index <= limit; ++fromLineRange.length)
            index = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ index, 0 }]);
        // To line count
        limit = range.location + [commitString length];
        for (index = range.location; index <= limit; ++toLineCount)
            index = NSMaxRange([self.contentString lineRangeForRange:(NSRange){ index, 0 }]);
        
        if ([commitString length])
        {
            NSMutableString *mutableContentString = [NSMutableString stringWithString:self.contentString];
            [mutableContentString replaceCharactersInRange:range withString:commitString];
            self.contentString = mutableContentString;
        }
        else
        {
            NSMutableString *mutableContentString = [NSMutableString stringWithString:self.contentString];
            [mutableContentString deleteCharactersInRange:range];
            self.contentString = mutableContentString;
        }
        
        [codeView updateTextInLineRange:fromLineRange toLineRange:(NSRange){ fromLineRange.location, toLineCount }];
    }
}

@end
