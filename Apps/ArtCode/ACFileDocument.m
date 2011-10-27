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

@property (nonatomic, strong) NSMutableString *contentString;
@property (nonatomic, strong) id<ECCodeParser>codeParser;
@property (nonatomic, strong, readonly) ECTextStyle *defaultTextStyle;
@end

@implementation ACFileDocument

@synthesize contentString = _contentString;
@synthesize codeParser = _codeParser;
@synthesize defaultTextStyle = _defaultTextStyle;
@synthesize theme = _theme;

- (void)setContentString:(NSMutableString *)contentString
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
    // TODO handle error
    self.contentString = [NSMutableString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:NULL];
    return YES;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(ECTextRenderer *)sender
{
    return [self.contentString length];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    // Preparing result
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[self.contentString substringWithRange:stringRange] attributes:self.defaultTextStyle.CTAttributes];
    
//    [self.codeParser visitScopesInRange:stringRange usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
////        NSLog(@"%@", scope);
//        return ECCodeVisitorResultRecurse;
//    }];
    
    return result;
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    if ([commitString length] != 0)
    {
        [self.contentString replaceCharactersInRange:range withString:commitString];
        [self updateChangeCount:UIDocumentChangeDone];
    }
    else
    {
        [self.contentString deleteCharactersInRange:range];
        [self updateChangeCount:UIDocumentChangeDone];
    }
}

@end
