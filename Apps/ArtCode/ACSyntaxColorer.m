//
//  ACSyntaxColorer.m
//  ArtCode
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSyntaxColorer.h"
#import <ECFoundation/ECFileBuffer.h>
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/TMTheme.h>
#import <ECUIKit/ECTextStyle.h>
#import <CoreText/CoreText.h>

#import <ECUIKit/ECTextRenderer.h>
#import <ECUIKit/ECCodeView.h>

@interface ACSyntaxColorer ()
{
    ECFileBuffer *_fileBuffer;
    ECCodeUnit *_codeUnit;
    id _fileBufferObserver;
    BOOL _needsToReapplySyntaxColoring;
}

- (void)_markPlaceholderWithName:(NSString *)name range:(NSRange)range;

@end

@implementation ACSyntaxColorer

@synthesize theme = _theme;
@synthesize defaultTextAttributes = _defaultTextAttributes;

- (id)initWithFileBuffer:(ECFileBuffer *)fileBuffer
{
    ECASSERT(fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _fileBuffer = fileBuffer;
    ECCodeIndex *codeIndex = [[ECCodeIndex alloc] init];
    _codeUnit = [codeIndex codeUnitForFileBuffer:fileBuffer scope:nil];
    _needsToReapplySyntaxColoring = YES;
//    _fileBufferObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ECFileBufferWillReplaceCharactersNotificationName object:fileBuffer queue:nil usingBlock:^(NSNotification *note) {
//        _needsToReapplySyntaxColoring = YES;
//    }];
    return self;
}

- (void)dealloc
{
//    [[NSNotificationCenter defaultCenter] removeObserver:_fileBufferObserver];
}

- (ECFileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (ECCodeUnit *)codeUnit
{
    return _codeUnit;
}

- (void)applySyntaxColoring
{
    if (!_needsToReapplySyntaxColoring)
        return;
    _needsToReapplySyntaxColoring = NO;
    
    NSRange range = NSMakeRange(0, [_fileBuffer length]);
//    [_fileBuffer setAttributes:self.defaultTextAttributes range:range];
    
    // Syntax coloring
    for (id<ECCodeToken>token in [_codeUnit annotatedTokensInRange:range])
        [_fileBuffer addAttributes:[self.theme attributesForScopeStack:[token scopeIdentifiersStack]] range:[token range]];
    
    // Placeholders
    static NSRegularExpression *placeholderRegExp = nil;
    if (!placeholderRegExp)
        placeholderRegExp = [NSRegularExpression regularExpressionWithPattern:@"<#(.+?)#>" options:0 error:NULL];
    for (NSTextCheckingResult *placeholderMatch in [_fileBuffer matchesOfRegexp:placeholderRegExp options:0])
    {
        [self _markPlaceholderWithName:[_fileBuffer stringInRange:[placeholderMatch rangeAtIndex:1]] range:placeholderMatch.range];
    }
}

#pragma mark - Private Methods

static CGFloat placeholderEndingsWidthCallback(void *refcon) {
    if (refcon)
    {
        CGFloat height = CTFontGetXHeight(refcon);
        return height / 2.0;
    }
    return 4.5;
}

static CTRunDelegateCallbacks placeholderEndingsRunCallbacks = {
    kCTRunDelegateVersion1,
    NULL,
    NULL,
    NULL,
    &placeholderEndingsWidthCallback
};

- (void)_markPlaceholderWithName:(NSString *)name range:(NSRange)range
{
    ECASSERT(range.length > 4);
    
    static CGColorRef placeholderFillColor = NULL;
    if (!placeholderFillColor)
        placeholderFillColor = CGColorRetain([UIColor colorWithRed:234.0/255.0 green:240.0/255.0 blue:250.0/255.0 alpha:1].CGColor);
    
    static CGColorRef placeholderStrokeColor = NULL;
    if (!placeholderStrokeColor)
        placeholderStrokeColor = CGColorRetain([UIColor colorWithRed:197.0/255.0 green:216.0/255.0 blue:243.0/255.0 alpha:1].CGColor);
    
    static ECTextRendererRunBlock placeHolderBodyBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextAddRect(context, rect);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), rect.origin.y);
        CGContextMoveToPoint(context, rect.origin.x, CGRectGetMaxY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    static ECTextRendererRunBlock placeholderLeftBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    static ECTextRendererRunBlock placeholderRightBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    // placeholder body style
    [_fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:placeHolderBodyBlock, ECTextRendererRunUnderlayBlockAttributeName, [UIColor blackColor].CGColor, kCTForegroundColorAttributeName, nil] range:NSMakeRange(range.location + 2, range.length - 4)];
    
    // Opening and Closing style
    
    //
    CGFontRef font = (__bridge CGFontRef)[self.defaultTextAttributes objectForKey:(__bridge id)kCTFontAttributeName];
    ECASSERT(font);
    CTRunDelegateRef delegateRef = CTRunDelegateCreate(&placeholderEndingsRunCallbacks, font);
    //
//    [_fileBuffer setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderLeftBlock, ECTextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(range.location, 2)];
//    [_fileBuffer setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderRightBlock, ECTextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(NSMaxRange(range) - 2, 2)];
    //
    CFRelease(delegateRef);
    
    // Placeholder behaviour
    [_fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:name, ECCodeViewPlaceholderAttributeName, nil] range:range];
}

@end
