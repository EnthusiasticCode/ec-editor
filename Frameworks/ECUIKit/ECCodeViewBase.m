//
//  ECCodeViewBase.m
//  CodeView
//
//  Created by Nicola Peduzzi on 01/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewBase.h"
#import "ECCodeStringDataSource.h"

#define TILE_HEIGHT 300

static const void *rendererContext;


@interface ECCodeViewBaseContentView : UIView
@property (nonatomic, weak) ECCodeViewBase *parentCodeView;
@end


@interface ECCodeViewBase () {
@private
    ECCodeViewBaseContentView *_contentView;
    
    // Dictionaries that holds additional passes
    NSMutableDictionary *overlayPasses;
    NSMutableDictionary *underlayPasses;
    
@package
    NSMutableDictionary *setupPasses;
    NSMutableDictionary *cleanupPasses;
}

@property (nonatomic, strong) ECTextRenderer *renderer;
@property (nonatomic, readonly) BOOL ownsRenderer;

- (void)_forwardTextInsetsToRenderer;

@end



@implementation ECCodeViewBase

#pragma mark Properties

@synthesize renderer = _renderer;

- (ECTextRenderer *)renderer
{
    if (_renderer == nil)
    {
        _renderer = [ECTextRenderer new];
        _renderer.delegate = self;
        _renderer.maximumStringLenghtPerSegment = 1024;
    }
    return _renderer;
}

- (BOOL)ownsRenderer
{
    return self.renderer.delegate == self;
}

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    // Setup renderer wrap with keeping in to account insets and line display
    if (self.ownsRenderer)
        self.renderer.renderWidth = frame.size.width;
    
    CGFloat contentHeight = self.renderer.renderHeight * self.contentScaleFactor;
    if (contentHeight == 0)
        contentHeight = frame.size.height;
    self.contentSize = CGSizeMake(frame.size.width, contentHeight);

    [super setFrame:frame];
}

- (void)setContentSize:(CGSize)contentSize
{
    // When the scrollview content size changes, reflect the same change to the content view
    CGSize size = CGSizeMake(ceilf(contentSize.width), ceilf(contentSize.height));
    [_contentView setFrame:self.renderer.isRenderHeightFinal ?
     (CGRect){ CGPointZero, size } :
     CGRectMake(0, 0, size.width, size.height + TILE_HEIGHT)];
    [super setContentSize:size];
}

@synthesize textInsets, lineNumbersEnabled, lineNumbersWidth, lineNumbersFont, lineNumbersColor, lineNumbersBackgroundColor;

- (void)setLineNumbersEnabled:(BOOL)enabled
{
    if (lineNumbersEnabled == enabled)
        return;
    
    [self willChangeValueForKey:@"lineNumbersEnabled"];
    
    lineNumbersEnabled = enabled;
    
    static NSString *lineNumberPassKey = @"LineNumbersUnderlayPass";
    if (lineNumbersEnabled)
    {
        __weak ECCodeViewBase *this = self;
        [self addPassLayerBlock:^(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
            CGContextSetFillColorWithColor(context, this->lineNumbersColor.CGColor);
            if (!line.isTruncation)
            {
                // Rendering line number
                // TODO get this more efficient. possibly by creating line numbers with preallocated characters.
                NSString *lineNumberString = [NSString stringWithFormat:@"%u", lineNumber + 1];
                CGSize lineNumberStringSize = [lineNumberString sizeWithFont:this->lineNumbersFont];
                
                CGContextSelectFont(context, this->lineNumbersFont.fontName.UTF8String, this->lineNumbersFont.pointSize, kCGEncodingMacRoman);
                CGContextSetTextDrawingMode(context, kCGTextFill);
                
                CGContextShowTextAtPoint(context, -lineBounds.origin.x + this->lineNumbersWidth - lineNumberStringSize.width - 2, line.descent + (lineBounds.size.height - lineNumberStringSize.height) / 2, lineNumberString.UTF8String, [lineNumberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
            }
            else
            {
                // Rendering dot
                CGContextFillEllipseInRect(context, CGRectMake(-lineBounds.origin.x + this->lineNumbersWidth - 3 - 4, (line.height - 3) / 2, 3, 3));
            }
        } underText:YES forKey:lineNumberPassKey];
    }
    else
    {
        [self removePassLayerForKey:lineNumberPassKey];
    }
    [self _forwardTextInsetsToRenderer];
    
    [self didChangeValueForKey:@"lineNumbersEnabled"];
}

- (void)setTextInsets:(UIEdgeInsets)insets
{
    if (UIEdgeInsetsEqualToEdgeInsets(insets, textInsets))
        return;
    
    [self willChangeValueForKey:@"textInsets"];
    textInsets = insets;
    [self _forwardTextInsetsToRenderer];
    [self didChangeValueForKey:@"textInsets"];
}

- (void)setLineNumbersWidth:(CGFloat)width
{
    if (width == lineNumbersWidth)
        return;
    
    [self willChangeValueForKey:@"lineNumbersWidth"];
    lineNumbersWidth = width;
    [self _forwardTextInsetsToRenderer];
    [self didChangeValueForKey:@"lineNumbersWidth"];
}

- (void)_forwardTextInsetsToRenderer
{
    UIEdgeInsets insets = self.textInsets;
    
    if (lineNumbersEnabled)
        insets.left += lineNumbersWidth;
    
    self.renderer.textInsets = insets;
}

#pragma mark View Methods

static void init(ECCodeViewBase *self)
{
    self.contentMode = UIViewContentModeRedraw;
    self->_contentView = [ECCodeViewBaseContentView new];
    self->_contentView.parentCodeView = self;
    self->_contentView.contentMode = UIViewContentModeRedraw;
    [self addSubview:self->_contentView];
    
    if (self.ownsRenderer)
        self.renderer.renderWidth = self.bounds.size.width;
    [self.renderer addObserver:self forKeyPath:@"renderHeight" options:NSKeyValueObservingOptionNew context:&rendererContext];
}

- (id)initWithFrame:(CGRect)frame renderer:(ECTextRenderer *)aRenderer
{    
    if (!(self = [super initWithFrame:frame]))
        return nil;
 
    self.renderer = aRenderer;

    init(self);

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    
    init(self);

    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
    if (!(self = [super initWithCoder:coder]))
        return nil;
    
    init(self);

    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    // Forwarding renderer calls
    if (aSelector == @selector(dataSource)
        || aSelector == @selector(setDataSource:)
        || aSelector == @selector(updateAllText)
        || aSelector == @selector(updateTextFromStringRange:toStringRange:))
        return self.renderer;
    return [super forwardingTargetForSelector:aSelector];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &rendererContext)
    {
        CGSize boundsSize = self.bounds.size;
        CGFloat height = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
        if (height == 0)
            height = boundsSize.height;
        CGFloat width = boundsSize.width;
        self.contentSize = CGSizeMake(width, height * self.contentScaleFactor);
    }
    else 
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self->lineNumbersEnabled)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        // Line number background
        [self->lineNumbersBackgroundColor setFill];
        CGContextFillRect(context, (CGRect){ rect.origin, CGSizeMake(self->lineNumbersWidth, rect.size.height) });
        [self->lineNumbersColor setStroke];
        CGContextSetLineWidth(context, 1);
        CGContextMoveToPoint(context, rect.origin.x + self->lineNumbersWidth + 0.5, rect.origin.y);
        CGContextAddLineToPoint(context, rect.origin.x + self->lineNumbersWidth + 0.5, CGRectGetMaxY(rect));
        CGContextStrokePath(context);
    }
}

#pragma mark - Text Renderer Delegate

- (void)textRenderer:(ECTextRenderer *)sender didInvalidateRenderInRect:(CGRect)rect
{
    if (rect.size.height == 0)
        [_contentView setNeedsDisplay];
    else
        [_contentView setNeedsDisplayInRect:rect];
}

#pragma mark - Text Decoration Methods

- (void)addPassLayerBlock:(ECTextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey
{
    [self addPassLayerBlock:block underText:isUnderlay forKey:passKey setupTileBlock:nil cleanupTileBlock:nil];
}

- (void)addPassLayerBlock:(ECTextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey setupTileBlock:(ECCodeViewBaseTileSetupBlock)setupBlock cleanupTileBlock:(ECCodeViewBaseTileSetupBlock)cleanupBlock
{
    if (isUnderlay)
    {
        if (!underlayPasses)
            underlayPasses = [NSMutableDictionary new];
        [underlayPasses setObject:[block copy] forKey:passKey];
        
        self.renderer.underlayRenderingPasses = [underlayPasses allValues];
    }
    else
    {
        if (!overlayPasses)
            overlayPasses = [NSMutableDictionary new];
        [overlayPasses setObject:[block copy] forKey:passKey];
        
        self.renderer.overlayRenderingPasses = [overlayPasses allValues];
    }
    
    if (setupBlock)
    {
        if (!setupPasses)
            setupPasses = [NSMutableDictionary new];
        [setupPasses setObject:[setupBlock copy] forKey:passKey];
    }
    
    if (cleanupBlock)
    {
        if (!cleanupPasses)
            cleanupPasses = [NSMutableDictionary new];
        [cleanupPasses setObject:[cleanupBlock copy] forKey:passKey];
    }
}

- (void)removePassLayerForKey:(NSString *)passKey
{
    [underlayPasses removeObjectForKey:passKey];
    [overlayPasses removeObjectForKey:passKey];
    [setupPasses removeObjectForKey:passKey];
    [cleanupPasses removeObjectForKey:passKey];
    
    self.renderer.underlayRenderingPasses = [underlayPasses allValues];
    self.renderer.overlayRenderingPasses = [overlayPasses allValues];
}

- (void)flashTextInRange:(NSRange)textRange
{
    ECRectSet *rects = [self.renderer rectsForStringRange:textRange limitToFirstLine:NO];
    
    // Scroll to center selected rect
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        [self scrollRectToVisible:CGRectInset(rects.bounds, -100, -100) animated:NO];
    } completion:^(BOOL finished) {
        [rects enumerateRectsUsingBlock:^(CGRect rect, BOOL *stop) {
            [[ECCodeFlashView new] flashInRect:rect view:self withDuration:0.15];
        }];
    }];
    
}

#pragma mark - Text Access Methods

- (NSString *)text
{
    if (self.dataSource == nil)
        return nil;
    
    return [[self.dataSource textRenderer:self.renderer attributedStringInRange:NSMakeRange(0, [self.dataSource stringLengthForTextRenderer:self.renderer])] string];
}

- (void)setText:(NSString *)string
{
    // TODO rethink this method
    if (self.dataSource == nil)
        self.dataSource = [ECCodeStringDataSource new];
    
    ECASSERT([self.dataSource isKindOfClass:[ECCodeStringDataSource class]]);
    
    if (!self.ownsRenderer)
        return;
    
    [(ECCodeStringDataSource *)self.dataSource setString:string];
    
    [self.renderer updateAllText];
    
    // Update tiles
    CGRect bounds = self.bounds;
    self.renderer.renderWidth = bounds.size.width;
    self.contentSize = CGSizeMake(bounds.size.width, self.renderer.renderHeight * self.contentScaleFactor);
    
    [_contentView setNeedsDisplay];
}

@end


@implementation ECCodeViewBaseContentView

@synthesize parentCodeView;

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (void)drawRect:(CGRect)rect
{
    ECASSERT(parentCodeView != nil);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [parentCodeView.backgroundColor setFill];
    CGContextFillRect(context, rect);
    
    // Setup tile passes
    [parentCodeView->setupPasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ((ECCodeViewBaseTileSetupBlock)obj)(context, rect);
    }];
    
    // Line number background
    if (parentCodeView.isLineNumbersEnabled)
    {
        [parentCodeView.lineNumbersBackgroundColor setFill];
        CGContextFillRect(context, (CGRect){ rect.origin, CGSizeMake(parentCodeView.lineNumbersWidth, rect.size.height) });
        [parentCodeView.lineNumbersColor setStroke];
        CGContextSetLineWidth(context, 1);
        CGContextMoveToPoint(context, rect.origin.x + parentCodeView.lineNumbersWidth + 0.5, rect.origin.y);
        CGContextAddLineToPoint(context, rect.origin.x + parentCodeView.lineNumbersWidth + 0.5, CGRectGetMaxY(rect));
        CGContextStrokePath(context);
    }

    // Drawing text
    if (rect.origin.y > 0)
        CGContextTranslateCTM(context, 0, rect.origin.y);
    [parentCodeView.renderer drawTextWithinRect:rect inContext:context];
    
    // Cleanup tile passes
    [parentCodeView->cleanupPasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ((ECCodeViewBaseTileSetupBlock)obj)(context, rect);
    }];
}

- (void)setFrame:(CGRect)frame
{
    ECASSERT(CGRectEqualToRect(frame, CGRectIntegral(frame)) && "If frame is not integral, the rendering is blurry.");
    
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    if (frame.size.width != self.frame.size.width)
        [(CATiledLayer *)self.layer setTileSize:CGSizeMake(frame.size.width, TILE_HEIGHT)];
    
    [super setFrame:frame];
}

@end


@implementation ECCodeFlashView

@synthesize cornerRadius, backgroundImage;

- (void)drawRect:(CGRect)rect
{    
    if (backgroundImage)
        [backgroundImage drawInRect:rect];
}

- (void)flashInRect:(CGRect)rect view:(UIView *)view withDuration:(NSTimeInterval)duration
{
    [self setNeedsDisplay];
    
    [view addSubview:self];
    self.contentMode = UIViewContentModeScaleToFill;
    self.frame = CGRectIntegral(rect);
    self.alpha = 0;
    self.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformMakeScale(1.7, 1.7);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration / 2 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
            self.alpha = 0;
            self.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }];
}

@end
