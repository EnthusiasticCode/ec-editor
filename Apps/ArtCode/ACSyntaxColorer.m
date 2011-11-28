//
//  ACSyntaxColorer.m
//  ArtCode
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSyntaxColorer.h"
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/TMTheme.h>
#import <ECUIKit/ECTextStyle.h>
#import <CoreText/CoreText.h>

#warning DEBUG
#import <ECUIKit/ECTextRenderer.h>
#import <ECUIKit/ECCodeView.h>

@interface ACSyntaxColorer ()
{
    ECAttributedUTF8FileBuffer *_fileBuffer;
    ECCodeUnit *_codeUnit;
    id _fileBufferObserver;
    BOOL _needsToReapplySyntaxColoring;
}
@end

@implementation ACSyntaxColorer

@synthesize theme = _theme;
@synthesize defaultTextAttributes = _defaultTextAttributes;

- (id)initWithFileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer
{
    ECASSERT(fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _fileBuffer = fileBuffer;
    ECCodeIndex *codeIndex = [[ECCodeIndex alloc] init];
    _codeUnit = [codeIndex codeUnitForFileBuffer:fileBuffer scope:nil];
    _needsToReapplySyntaxColoring = YES;
    _fileBufferObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ECFileBufferWillReplaceCharactersNotificationName object:fileBuffer queue:nil usingBlock:^(NSNotification *note) {
        _needsToReapplySyntaxColoring = YES;
    }];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_fileBufferObserver];
}

- (ECAttributedUTF8FileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (ECCodeUnit *)codeUnit
{
    return _codeUnit;
}

static CGFloat widthCallback(void *refcon) {
    if (refcon)
    {
        CGFloat height = CTFontGetXHeight(refcon);
        return height / 2.0;
    }
    return 4.5;
}

- (void)applySyntaxColoring
{
    if (!_needsToReapplySyntaxColoring)
        return;
    NSRange range = NSMakeRange(0, [_fileBuffer length]);
    [_fileBuffer setAttributes:self.defaultTextAttributes range:range];
    for (id<ECCodeToken>token in [_codeUnit annotatedTokensInRange:range])
        [_fileBuffer addAttributes:[self.theme attributesForScopeStack:[token scopeIdentifiersStack]] range:[token range]];
    _needsToReapplySyntaxColoring = NO;
    
#warning DEBUG
    // placeholder body style
    [_fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGContextSetFillColorWithColor(context, [UIColor colorWithRed:234.0/255.0 green:240.0/255.0 blue:250.0/255.0 alpha:1].CGColor);
        CGContextAddRect(context, rect);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), rect.origin.y);
        CGContextMoveToPoint(context, rect.origin.x, CGRectGetMaxY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:197.0/255.0 green:216.0/255.0 blue:243.0/255.0 alpha:1].CGColor);
        CGContextStrokePath(context);
    } copy], ECTextRendererRunUnderlayBlockAttributeName, [UIColor blackColor].CGColor, kCTForegroundColorAttributeName, nil] range:NSMakeRange(10, 5)];
    
    // Opening and Closing style
    CTRunDelegateCallbacks callbacks = {
        kCTRunDelegateVersion1,
        NULL,
        NULL,
        NULL,
        &widthCallback
    };
    //E<#odeVi#>.m
    CGFontRef font = (__bridge CGFontRef)[self.defaultTextAttributes objectForKey:(__bridge id)kCTFontAttributeName];
    ECASSERT(font);
    CTRunDelegateRef delegateRef = CTRunDelegateCreate(&callbacks, font);
    //
    [_fileBuffer setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, [UIColor colorWithRed:234.0/255.0 green:240.0/255.0 blue:250.0/255.0 alpha:1].CGColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:197.0/255.0 green:216.0/255.0 blue:243.0/255.0 alpha:1].CGColor);
        CGContextStrokePath(context);
    }, ECTextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(8, 2)];
    [_fileBuffer setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, [UIColor colorWithRed:234.0/255.0 green:240.0/255.0 blue:250.0/255.0 alpha:1].CGColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:197.0/255.0 green:216.0/255.0 blue:243.0/255.0 alpha:1].CGColor);
        CGContextStrokePath(context);
    }, ECTextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(15, 2)];
    //
    CFRelease(delegateRef);
    
    // Placeholder behaviour
    [_fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], ECCodeViewPlaceholderAttributeName, nil] range:NSMakeRange(8, 9)];
}

@end
