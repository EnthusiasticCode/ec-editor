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


@interface ECCodeViewBaseContentView : UIView
@property (nonatomic, weak) ECCodeViewBase *parentCodeView;
@end


@interface ECCodeViewBase () {
@private
    ECCodeViewBaseContentView *_contentView;
    
    // Dictionaries that holds additional passes
    NSMutableDictionary *overlayPasses;
    NSMutableDictionary *underlayPasses;
    
    BOOL dataSourceHasStringRangeForLineRange;
}

@property (nonatomic, strong) ECTextRenderer *renderer;
@property (nonatomic, readonly) BOOL ownsRenderer;

@end



@implementation ECCodeViewBase

#pragma mark Properties

@synthesize datasource = _datasource;
@synthesize renderingQueue = _renderingQueue, renderer = _renderer;
@synthesize textInsets, lineNumbersEnabled, lineNumbersWidth, lineNumbersFont, lineNumbersColor, lineNumberRenderingBlock;

- (void)setDatasource:(id<ECCodeViewBaseDataSource>)datasource
{
    if (datasource == _datasource)
        return;
    
    [self willChangeValueForKey:@"datasource"];
    
    _datasource = datasource;
    dataSourceHasStringRangeForLineRange = [_datasource respondsToSelector:@selector(codeView:stringRangeForLineRange:)];
    [_renderer updateAllText];
    
    [self didChangeValueForKey:@"datasource"];
}

- (ECTextRenderer *)renderer
{
    if (_renderer == nil)
    {
        _renderer = [ECTextRenderer new];
        _renderer.delegate = self;
        _renderer.datasource = self;
        _renderer.preferredLineCountPerSegment = 500;
    }
    return _renderer;
}

- (BOOL)ownsRenderer
{
    return self.renderer.delegate == self;
}

- (NSOperationQueue *)renderingQueue
{
    if (_renderingQueue == nil)
    {
        _renderingQueue = [NSOperationQueue new];
        [_renderingQueue setMaxConcurrentOperationCount:1];
    }
    return _renderingQueue;
}

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    // Setup renderer wrap with keeping in to account insets and line display
    if (self.ownsRenderer)
        self.renderer.wrapWidth = frame.size.width;
    
    CGFloat contentHeight = self.renderer.estimatedHeight * self.contentScaleFactor;
    if (contentHeight == 0)
        contentHeight = frame.size.height;
    self.contentSize = CGSizeMake(frame.size.width, contentHeight);

    [super setFrame:frame];
}

- (void)setContentSize:(CGSize)contentSize
{
    [_contentView setFrame:(CGRect){ CGPointZero, contentSize }];
    [super setContentSize:contentSize];
}

- (void)setLineNumbersEnabled:(BOOL)enabled
{
    if (lineNumbersEnabled == enabled)
        return;
    
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
}

#pragma mark NSObject Methods

static void init(ECCodeViewBase *self)
{
    self->_contentView = [ECCodeViewBaseContentView new];
    self->_contentView.parentCodeView = self;
    self->_contentView.contentMode = UIViewContentModeRedraw;
    [self addSubview:self->_contentView];
    
    if (self.ownsRenderer)
        self.renderer.wrapWidth = self.bounds.size.width;
    [self.renderer addObserver:self forKeyPath:@"estimatedHeight" options:NSKeyValueObservingOptionNew context:nil];
}

- (id)initWithFrame:(CGRect)frame renderer:(ECTextRenderer *)aRenderer renderingQueue:(NSOperationQueue *)queue
{    
    if (!(self = [super initWithFrame:frame]))
        return nil;
 
    self.renderer = aRenderer;
    self.renderingQueue = queue;

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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.renderer)
    {
        CGSize boundsSize = self.bounds.size;
        CGFloat height = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
        if (height == 0)
            height = boundsSize.height;
        CGFloat width = boundsSize.width;
        self.contentSize = CGSizeMake(width, height * self.contentScaleFactor);
    }
}

#pragma mark - Rendering Methods

- (void)updateAllText
{
    [self.renderer updateAllText];
}

- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange
{
    [self.renderer updateTextInLineRange:originalRange toLineRange:newRange];
}

#pragma mark - Text Renderer Delegate

- (UIEdgeInsets)textInsetsForTextRenderer:(ECTextRenderer *)sender
{
    UIEdgeInsets insets = textInsets;
    if (lineNumbersEnabled)
        insets.left += lineNumbersWidth;
    return insets;
}

- (NSArray *)underlayPassesForTextRenderer:(ECTextRenderer *)sender
{
    return [underlayPasses allValues];
}


- (NSArray *)overlayPassesForTextRenderer:(ECTextRenderer *)sender
{
    return [overlayPasses allValues];
}

- (void)textRenderer:(ECTextRenderer *)sender invalidateRenderInRect:(CGRect)rect
{
#warning TODO fix rect with insects
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

#pragma mark - Text Renderer Data source

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString
{
    ECASSERT(sender == self.renderer);
    
    if (self.datasource == nil)
        return nil;
    
    NSRange stringRange = NSMakeRange(0, 0);
    if (dataSourceHasStringRangeForLineRange)
    {
        stringRange = [self.datasource codeView:self stringRangeForLineRange:lineRange];
    }
    else
    {
#warning NIK TODO!!! optimize line to string range conversion
        NSUInteger lineIndex, stringLength = [self.datasource textLength];
        NSString *contentString = [self.datasource codeView:self attributedStringInRange:NSMakeRange(0, stringLength)].string;
        
        // Calculate string range location for query line range location
        for (lineIndex = 0; lineIndex < lineRange->location; ++lineIndex)
            stringRange.location = NSMaxRange([contentString lineRangeForRange:(NSRange){ stringRange.location, 0 }]);
        
        if (stringRange.location < stringLength)
        {        
            // Calculate string range lenght for query line range length
            stringRange.length = stringRange.location;
            for (lineIndex = 0; lineIndex < lineRange->length && stringRange.length < stringLength; ++lineIndex)
                stringRange.length = NSMaxRange([contentString lineRangeForRange:(NSRange){ stringRange.length, 0 }]);
            stringRange.length -= stringRange.location;
            
            // Assign return read count of lines
            lineRange->length = lineIndex;
        }
    }
    
    if (endOfString)
        *endOfString = (NSMaxRange(stringRange) == [self.datasource textLength]);
    
    return [self.datasource codeView:self attributedStringInRange:stringRange];
}

#pragma mark - Text Renderer and CodeView String Datasource

- (NSString *)text
{
    if (_datasource == nil)
        return nil;
    
    if (![self.datasource isKindOfClass:[ECCodeStringDataSource class]])
        return nil;
    
    return [(ECCodeStringDataSource *)_datasource string];
}

- (void)setText:(NSString *)string
{
    if (_datasource == nil)
        self.datasource = [ECCodeStringDataSource new];
    
    ECASSERT([self.datasource isKindOfClass:[ECCodeStringDataSource class]]);
    
    if (!self.ownsRenderer)
        return;
    
    [(ECCodeStringDataSource *)_datasource setString:string];
    
    [self.renderer updateAllText];
    
    // Update tiles
    CGRect bounds = self.bounds;
    self.renderer.wrapWidth = bounds.size.width;
    self.contentSize = CGSizeMake(bounds.size.width, self.renderer.estimatedHeight * self.contentScaleFactor);
    
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
    
    //    CGFloat scale = parent.contentScaleFactor;
    //    CGFloat invertScale = 1.0 / scale;
    
    // Draw background
//    if ((int)(rect.origin.y / TILE_HEIGHT) % 2)
//        [[UIColor grayColor] setFill];
//    else
        [parentCodeView.backgroundColor setFill];
    CGContextFillRect(context, rect);
    
    // Positioning text
    //    CGContextScaleCTM(imageContext, scale, scale);
    
    //    CGRect textRect = rect;
    //    if (textInsets.top > 0)
    //    {
    //        if (textRect.origin.y > textInsets.top)
    //            textRect.origin.y -= textInsets.top;
    //        else
    //            textRect.origin.y = 0;
    //        textRect.size.width -= textInsets.top;
    //        CGContextTranslateCTM(context, 0, -textInsets.top);
    //    }
    
    //    CGPointMake(, rect.size.height * this->tileIndex * invertScale);
    
    //    CGSize textSize = rect.size;
    //    textSize.height *= invertScale;
    //    textSize.width *= invertScale;
    
    // Drawing text
    CGContextTranslateCTM(context, 0, rect.origin.y);
    [parentCodeView.renderer drawTextWithinRect:rect inContext:context];
}

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    if (frame.size.width != self.frame.size.width)
        [(CATiledLayer *)self.layer setTileSize:CGSizeMake(frame.size.width, TILE_HEIGHT)];
    
    [super setFrame:frame];
}

@end

