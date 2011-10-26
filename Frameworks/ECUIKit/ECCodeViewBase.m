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
}

@property (nonatomic, strong) ECTextRenderer *renderer;
@property (nonatomic, readonly) BOOL ownsRenderer;

- (void)_forwardTextInsetsToRenderer;

@end



@implementation ECCodeViewBase

#pragma mark Properties

@dynamic datasource;
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
    CGRect contentRect = CGRectMake(0, 0, ceilf(contentSize.width), ceilf(contentSize.height));
    [_contentView setFrame:contentRect];
    [super setContentSize:contentRect.size];
}

@synthesize textInsets, lineNumbersEnabled, lineNumbersWidth, lineNumbersFont, lineNumbersColor;

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
        __block NSUInteger lastLine = NSUIntegerMax;
        [self addPassLayerBlock:^(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
            // Rendering line number
            if (lastLine != lineNumber)
            {
                // TODO get this more efficient. possibly by creating line numbers with preallocated characters.
                NSString *lineNumberString = [NSString stringWithFormat:@"%u", lineNumber + 1];
                CGSize lineNumberStringSize = [lineNumberString sizeWithFont:this->lineNumbersFont];
                
                CGContextSelectFont(context, this->lineNumbersFont.fontName.UTF8String, this->lineNumbersFont.pointSize, kCGEncodingMacRoman);
                CGContextSetTextDrawingMode(context, kCGTextFill);
                CGContextSetFillColorWithColor(context, this->lineNumbersColor.CGColor);
                
                CGContextShowTextAtPoint(context, -lineBounds.origin.x + this->lineNumbersWidth - lineNumberStringSize.width, line.descent + (lineBounds.size.height - lineNumberStringSize.height) / 2, lineNumberString.UTF8String, [lineNumberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
            }
            
            lastLine = lineNumber;
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

#pragma mark NSObject Methods

static void init(ECCodeViewBase *self)
{
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
    if (aSelector == @selector(datasource)
        || aSelector == @selector(setDatasource:)
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

#pragma mark - Text Renderer Delegate

- (void)textRenderer:(ECTextRenderer *)sender didInvalidateRenderInRect:(CGRect)rect
{
    if (rect.size.height == 0)
        [_contentView setNeedsDisplay];
    else
        [_contentView setNeedsDisplayInRect:rect];
}

#pragma mark -

- (void)addPassLayerBlock:(ECTextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey
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
}

- (void)removePassLayerForKey:(NSString *)passKey
{
    [underlayPasses removeObjectForKey:passKey];
    [overlayPasses removeObjectForKey:passKey];
    
    self.renderer.underlayRenderingPasses = [underlayPasses allValues];
    self.renderer.overlayRenderingPasses = [overlayPasses allValues];
}

#pragma mark - Text Renderer Data source

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    ECASSERT(sender == self.renderer);
    
    if (self.datasource == nil)
        return nil;
    
    return [self.datasource textRenderer:self.renderer attributedStringInRange:stringRange];
}

- (NSUInteger)stringLengthForTextRenderer:(ECTextRenderer *)sender
{
    ECASSERT(sender == self.renderer);
    
    if (self.datasource == nil)
        return 0;
    
    return [self.datasource stringLengthForTextRenderer:self.renderer];
}

#pragma mark - Text Renderer and CodeView String Datasource

- (NSString *)text
{
    if (self.datasource == nil)
        return nil;
    
    if (![self.datasource isKindOfClass:[ECCodeStringDataSource class]])
        return nil;
    
    return [(ECCodeStringDataSource *)self.datasource string];
}

- (void)setText:(NSString *)string
{
    if (self.datasource == nil)
        self.datasource = [ECCodeStringDataSource new];
    
    ECASSERT([self.datasource isKindOfClass:[ECCodeStringDataSource class]]);
    
    if (!self.ownsRenderer)
        return;
    
    [(ECCodeStringDataSource *)self.datasource setString:string];
    
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
    
    // Drawing text
    if (rect.origin.y > 0)
        CGContextTranslateCTM(context, 0, rect.origin.y);
    [parentCodeView.renderer drawTextWithinRect:rect inContext:context];
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

