//
//  ECCodeViewBase.m
//  CodeView
//
//  Created by Nicola Peduzzi on 01/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewBase.h"
#import "ECCodeStringDataSource.h"

#define TILEVIEWPOOL_SIZE (3)

#pragma mark -
#pragma mark Interfaces

@class TextTileView;

#pragma mark -

@interface ECCodeViewBase () {
@private
    NSMutableAttributedString *text;
    ECCodeStringDataSource *defaultDatasource;
    
    // Tileing and rendering management
    TextTileView* tileViewPool[TILEVIEWPOOL_SIZE];
    
    // Dictionaries that holds additional passes
    NSMutableDictionary *overlayPasses;
    NSMutableDictionary *underlayPasses;
}

@property (nonatomic, strong) ECTextRenderer *renderer;
@property (nonatomic, readonly) BOOL ownsRenderer;

/// Get or create a tile for the given index.
- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex;

@end

#pragma mark -
@interface TextTileView : UIView {
@private
    CALayer *textLayer;
}

@property (nonatomic, readonly, weak) ECCodeViewBase *parent;
@property (nonatomic) NSInteger tileIndex;
- (id)initWithCodeViewBase:(ECCodeViewBase *)codeView;
- (void)invalidate;
- (void)renderText;

@end

#pragma mark - Implementations

#pragma mark - TextTileView

@implementation TextTileView

@synthesize parent, tileIndex;

#pragma mark Properties

- (void)setTileIndex:(NSInteger)index
{
    if (index != tileIndex) 
    {
        tileIndex = index;
        [self setNeedsDisplay];
    }
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [textLayer setFrame:bounds];
}

- (void)setBackgroundColor:(UIColor *)color
{
    [super setBackgroundColor:color];
    [self setNeedsDisplay];
}


#pragma mark Methods

- (id)initWithCodeViewBase:(ECCodeViewBase *)codeView
{
    if ((self = [super init]))
    {
        parent = codeView;
        
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        
        textLayer = [CALayer layer];
        textLayer.actions = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], @"bounds",
                             [NSNull null], @"contents",
                             [NSNull null], @"hidden", 
                             [NSNull null], @"opacity", nil];
        textLayer.hidden = YES;
        [self.layer addSublayer:textLayer];
        [textLayer setFrame:self.bounds];
        
        [self invalidate];
    }
    return self;
}

- (void)invalidate
{
    tileIndex = -2;
    self.hidden = YES;
}

- (void)renderText
{
    if (tileIndex < 0)
        return;
    
    CGFloat scale = parent.contentScaleFactor;
    CGFloat invertScale = 1.0 / scale;
    CGRect rect = self.bounds;
    
    __weak TextTileView* this = self;
    [parent.renderingQueue addOperationWithBlock:^(void) {
        // Rendering image
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
        CGContextRef imageContext = UIGraphicsGetCurrentContext();
        {
            // Draw background
            [this.backgroundColor setFill];
            CGContextFillRect(imageContext, rect);
            
            // Positioning text
            CGContextScaleCTM(imageContext, scale, scale);
            CGPoint textOffset = CGPointMake(0, rect.size.height * this->tileIndex * invertScale);

            CGSize textSize = rect.size;
            textSize.height *= invertScale;
            textSize.width *= invertScale;
            
            // Drawing text
            [this->parent.renderer drawTextWithinRect:(CGRect){ textOffset, textSize } inContext:imageContext];
        }
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // Send rendered image to presentation layer
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            this->textLayer.contents = (__bridge id)image.CGImage;
            this->textLayer.hidden = NO;
        }];
    }];
}

- (void)drawRect:(CGRect)rect
{
    [self renderText];
}

@end

#pragma mark -
#pragma mark ECCodeView

@implementation ECCodeViewBase

#pragma mark Properties

@synthesize datasource;
@synthesize renderingQueue = _renderingQueue, renderer = _renderer;
@synthesize textInsets, lineNumbersEnabled, lineNumbersWidth, lineNumbersFont, lineNumbersColor, lineNumberRenderingBlock;

- (id<ECCodeViewBaseDataSource>)datasource
{
    if (!datasource)
    {
        if (!defaultDatasource)
            defaultDatasource = [ECCodeStringDataSource new];
        self.datasource = defaultDatasource;
    }
    return datasource;
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
    
    self.contentSize = CGSizeMake(frame.size.width, self.renderer.estimatedHeight * self.contentScaleFactor);
    
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, frame.size };
    }

    [super setFrame:frame];
}

- (void)setBackgroundColor:(UIColor *)color
{
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] setBackgroundColor:color];
    }
    [super setBackgroundColor:color];
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
        // Operating in the main queue because this message can be generated in the renderingQueue
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat height = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
            CGFloat width = self.bounds.size.width;
            self.contentSize = CGSizeMake(width, height * self.contentScaleFactor); 
        });
    }
}

#pragma mark - Rendering Methods

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.subviews makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex
{
    NSInteger selected = -1;
    // Select free tile
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i) 
    {
        if (tileViewPool[i])
        {
            // Tile already present and ready
            if ([tileViewPool[i] tileIndex] == (NSInteger)tileIndex)
            {
                return tileViewPool[i];
            }
            // If still no selection just select this as a candidate
            if (selected >= 0)
                continue;
            // Select only if better than previous
            if (abs([tileViewPool[i] tileIndex] - tileIndex) <= 1) 
                continue;
        }
        selected = i;
    }
    
    // Generate new tile
    if (!tileViewPool[selected]) 
    {
        tileViewPool[selected] = [[TextTileView alloc] initWithCodeViewBase:self];
        tileViewPool[selected].backgroundColor = self.backgroundColor;
        // TODO remove from self when not displayed
        [self addSubview:tileViewPool[selected]];
    }
    
    tileViewPool[selected].bounds = (CGRect){ CGPointZero, self.frame.size };
    tileViewPool[selected].tileIndex = tileIndex;
    
    return tileViewPool[selected];
}

- (void)layoutSubviews
{
    // Scrolled content rect
    CGRect contentRect = self.bounds;
    CGFloat halfHeight = contentRect.size.height / 2.0;
    
    // Find first visible tile index
    NSUInteger index = contentRect.origin.y / contentRect.size.height;
    
    // Layout first visible tile
    CGFloat firstTileEnd = (index + 1) * contentRect.size.height;
    TextTileView *firstTile = [self viewForTileIndex:index];
    [self sendSubviewToBack:firstTile];
    firstTile.hidden = NO;
    firstTile.center = CGPointMake(CGRectGetMidX(contentRect), firstTileEnd - halfHeight);
    
    // Layout second visible tile if needed
    if (firstTileEnd < CGRectGetMaxY(contentRect)) 
    {
        index++;
        TextTileView *secondTile = [self viewForTileIndex:index];
        [self sendSubviewToBack:secondTile];
        secondTile.hidden = NO;
        secondTile.center = CGPointMake(CGRectGetMidX(contentRect), firstTileEnd + halfHeight);
    }
}

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
    if (rect.origin.y <= CGRectGetMaxY(self.bounds)) 
    {
        for (int i = 0; i < TILEVIEWPOOL_SIZE; ++i) 
        {
            [tileViewPool[i] invalidate];
        }
        [self setNeedsLayout];
    }
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
    
    NSRange stringRange = [self.datasource codeView:self stringRangeForLineRange:lineRange];
    
    if (endOfString)
        *endOfString = (NSMaxRange(stringRange) == [self.datasource textLength]);
    
    return [self.datasource codeView:self stringInRange:stringRange];
}

#pragma mark - Text Renderer and CodeView String Datasource

- (NSString *)text
{
    if (![self.datasource isKindOfClass:[ECCodeStringDataSource class]])
    {
        return nil;
    }
    
    return [(ECCodeStringDataSource *)datasource string];
}

- (void)setText:(NSString *)string
{
    ECASSERT([self.datasource isKindOfClass:[ECCodeStringDataSource class]]);
    
    if (!self.ownsRenderer)
        return;
    
    [(ECCodeStringDataSource *)datasource setString:string];
    
    [self.renderer updateAllText];
    
    // Update tiles
    CGRect bounds = self.bounds;
    self.renderer.wrapWidth = bounds.size.width;
    self.contentSize = CGSizeMake(bounds.size.width, self.renderer.estimatedHeight * self.contentScaleFactor);
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, bounds.size };
    }
    
    [self setNeedsLayout];
}

@end
