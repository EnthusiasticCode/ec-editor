//
//  CodeFile.m
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFile.h"
#import "TMTheme.h"
#import "FileBuffer.h"
#import "TMIndex.h"
#import "TMUnit.h"
#import "TMScope.h"

@interface CodeFile ()
{
    NSOperationQueue *_consumerOperationQueue;
}
@property (nonatomic, strong) TMUnit *codeUnit;
- (void)_markPlaceholderWithName:(NSString *)name range:(NSRange)range;
@end

@implementation CodeFile

@synthesize fileBuffer = _fileBuffer, codeUnit = _codeUnit;
@synthesize theme = _theme;

- (TMTheme *)theme
{
    if (!_theme)
        _theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
    return _theme;
}

- (id)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (!self)
        return nil;
    _consumerOperationQueue = [[NSOperationQueue alloc] init];
    _consumerOperationQueue.maxConcurrentOperationCount = 1;
    _fileBuffer = [[FileBuffer alloc] initWithFileURL:fileURL];
    _codeUnit = [[[TMIndex alloc] init] codeUnitForFileBuffer:_fileBuffer rootScopeIdentifier:nil];
    return self;
}

+ (void)saveFilesToDisk
{
    [FileBuffer saveAllBuffers];
}

#pragma mark - FileBufferConsumer

- (NSOperationQueue *)consumerOperationQueue
{
    return _consumerOperationQueue;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(TextRenderer *)sender
{
    return [self.fileBuffer length];
}

- (NSAttributedString *)textRenderer:(TextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self.fileBuffer attributedStringInRange:stringRange]];
    // Add text coloring
    [attributedString addAttributes:[TMTheme defaultAttributes] range:NSMakeRange(0, [attributedString length])];
    [self.codeUnit visitScopesInRange:stringRange options:TMUnitVisitOptionsRelativeRange withBlock:^TMUnitVisitResult(TMScope *scope, NSRange range) {
        NSDictionary *attributes = [self.theme attributesForScope:scope];
        if ([attributes count])
            [attributedString addAttributes:attributes range:range];
        return TMUnitVisitResultRecurse;
    }];
    // Add placeholders styles
    static NSRegularExpression *placeholderRegExp = nil;
    if (!placeholderRegExp)
        placeholderRegExp = [NSRegularExpression regularExpressionWithPattern:@"<#(.+?)#>" options:0 error:NULL];
    for (NSTextCheckingResult *placeholderMatch in [self.fileBuffer matchesOfRegexp:placeholderRegExp options:0])
    {
        [self _markPlaceholderWithName:[self.fileBuffer stringInRange:[placeholderMatch rangeAtIndex:1]] range:placeholderMatch.range];
    }
    return attributedString;
}

- (NSDictionary *)defaultTextAttributedForTextRenderer:(TextRenderer *)sender
{
    return [TMTheme defaultAttributes];
}

- (void)codeView:(CodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    [self.fileBuffer replaceCharactersInRange:range withString:commitString];
}

- (id)codeView:(CodeView *)codeView attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange
{
    return [self.fileBuffer attribute:attributeName atIndex:index longestEffectiveRange:effectiveRange];
}

#pragma mark - Private methods

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
    
    static TextRendererRunBlock placeHolderBodyBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
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
    
    static TextRendererRunBlock placeholderLeftBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
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
    
    static TextRendererRunBlock placeholderRightBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
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
    [self.fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:placeHolderBodyBlock, TextRendererRunUnderlayBlockAttributeName, [UIColor blackColor].CGColor, kCTForegroundColorAttributeName, nil] range:NSMakeRange(range.location + 2, range.length - 4)];
    
    // Opening and Closing style
    
    //
    CGFontRef font = (__bridge CGFontRef)[[TMTheme defaultAttributes] objectForKey:(__bridge id)kCTFontAttributeName];
    ECASSERT(font);
    CTRunDelegateRef delegateRef = CTRunDelegateCreate(&placeholderEndingsRunCallbacks, font);
    
    [self.fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderLeftBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(range.location, 2)];
    [self.fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderRightBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(NSMaxRange(range) - 2, 2)];
    
    CFRelease(delegateRef);
    
    // Placeholder behaviour
    [self.fileBuffer addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:name, CodeViewPlaceholderAttributeName, nil] range:range];
}

@end
