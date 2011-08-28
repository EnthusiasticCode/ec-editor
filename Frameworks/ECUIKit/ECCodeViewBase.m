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
    
    // Variable to indicate if renderer and rendering queue are owned by this codeview
    BOOL ownsRenderer;
}

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
@property (nonatomic) UIEdgeInsets textInsets;
- (id)initWithCodeViewBase:(ECCodeViewBase *)codeView;
- (void)invalidate;
- (void)renderText;

@end

#pragma mark -
#pragma mark Implementations

#pragma mark -
#pragma mark TextTileView

@implementation TextTileView

@synthesize parent, tileIndex, textInsets;

#pragma mark Properties

- (void)setTileIndex:(NSInteger)index
{
    if (index != tileIndex) 
    {
        tileIndex = index;
        [self renderText];
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
    [self renderText];
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
            LineNumberRenderingBlock lineBlock = this->parent.lineNumberRenderingBlock;
            
            // Draw background
            [this.backgroundColor setFill];
            CGContextFillRect(imageContext, rect);
            
            // Positioning text
            CGContextScaleCTM(imageContext, scale, scale);
            CGPoint textOffset = CGPointMake(0, rect.size.height * this->tileIndex * invertScale);
            CGFloat lineNumberWidth = this->parent.lineNumberWidth;
            if (this->tileIndex == 0) 
            {
                CGContextTranslateCTM(imageContext, this->textInsets.left + lineNumberWidth, this->textInsets.top);
            }
            else
            {
                textOffset.y -= this->textInsets.top;
                CGContextTranslateCTM(imageContext, this->textInsets.left + lineNumberWidth, 0);
            }
            
            CGSize textSize = rect.size;
            textSize.height *= invertScale;
            textSize.width *= invertScale;
            
            // Drawing text
            if (lineNumberWidth > 0 && this->parent.lineNumberFont)
            {
                const char *lineNumberFontName = this->parent.lineNumberFont.fontName.UTF8String;
                CGFloat lineNumberSize = this->parent.lineNumberFont.pointSize;
                CGColorRef lineNumberColor = this->parent.lineNumberColor.CGColor;
                CGFloat textInsetsLeft = this->textInsets.left;
                
                @autoreleasepool {
                    __block NSUInteger lastLine = NSUIntegerMax;
                    [this->parent.renderer drawTextWithinRect:(CGRect){ textOffset, textSize } inContext:imageContext withLineBlock:^(ECTextRendererLine *line, NSUInteger lineNumber) {
                        CGContextSaveGState(imageContext);
                        {
                            CGSize lineNumberBoundsSize = CGSizeMake(lineNumberWidth, line.height);
                            
                            // Rendering line number
                            if (lastLine != lineNumber)
                            {
                                // TODO get this more efficient. possibly by creating line numbers with preallocated characters.
                                NSString *lineNumberString = [NSString stringWithFormat:@"%u", lineNumber + 1];
                                CGSize lineNumberStringSize = [lineNumberString sizeWithFont:this->parent.lineNumberFont];
                                
                                CGContextSelectFont(imageContext, lineNumberFontName, lineNumberSize, kCGEncodingMacRoman);
                                CGContextSetTextDrawingMode(imageContext, kCGTextFill);
                                CGContextSetFillColorWithColor(imageContext, lineNumberColor);

                                CGContextShowTextAtPoint(imageContext, -lineNumberStringSize.width - textInsetsLeft, -lineNumberBoundsSize.height + lineNumberStringSize.height / 2, lineNumberString.UTF8String, [lineNumberString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
                            }
                            
                            if (lineBlock)
                            {
                                CGContextTranslateCTM(imageContext, -lineNumberBoundsSize.width - textInsetsLeft, -lineNumberBoundsSize.height);
                                lineBlock(imageContext, (CGRect){ CGPointZero, lineNumberBoundsSize }, line.ascent, lineNumber, (lastLine == lineNumber));                                                
                            }
                        }
                        CGContextRestoreGState(imageContext);
                        CGContextSetTextMatrix(imageContext, CGAffineTransformIdentity);
                        lastLine = lineNumber;
                    }];
                }
            }
            else
            {
                [this->parent.renderer drawTextWithinRect:(CGRect){ textOffset, textSize } inContext:imageContext withLineBlock:nil];
            }
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

@end

#pragma mark -
#pragma mark ECCodeView

@implementation ECCodeViewBase

#pragma mark Properties

@synthesize datasource; 
@synthesize textInsets;
@synthesize renderingQueue, renderer;
@synthesize lineNumberWidth, lineNumberFont, lineNumberColor, lineNumberRenderingBlock;

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

- (void)setDatasource:(id<ECCodeViewDataSource>)aDatasource
{
    datasource = aDatasource;
    if (ownsRenderer)
        renderer.datasource = datasource;
}

- (void)setTextInsets:(UIEdgeInsets)insets
{
    textInsets = insets;
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] setTextInsets:insets];
    }
}

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    // Setup renderer wrap with keeping in to account insets and line display
    if (ownsRenderer)
        renderer.wrapWidth = UIEdgeInsetsInsetRect(frame, self->textInsets).size.width - lineNumberWidth;
    
    self.contentSize = CGSizeMake(frame.size.width, (renderer.estimatedHeight + textInsets.top + textInsets.bottom) * self.contentScaleFactor);
    
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

#pragma mark NSObject Methods

static void preinit(ECCodeViewBase *self)
{
    self->ownsRenderer = YES;
    
    // Creating new renderer
    self->renderer = [ECTextRenderer new];
    self->renderer.delegate = self;
    self->renderer.preferredLineCountPerSegment = 500;
    
    // Creating rendering queue
    self->renderingQueue = [NSOperationQueue new];
    [self->renderingQueue setMaxConcurrentOperationCount:1];
    
    self->textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

static void init(ECCodeViewBase *self)
{
    if (self->ownsRenderer)
        self->renderer.wrapWidth = UIEdgeInsetsInsetRect(self.bounds, self->textInsets).size.width;
    [self->renderer addObserver:self forKeyPath:@"estimatedHeight" options:NSKeyValueObservingOptionNew context:nil];
}

- (id)initWithFrame:(CGRect)frame renderer:(ECTextRenderer *)aRenderer renderingQueue:(NSOperationQueue *)queue
{
    ownsRenderer = NO;
    renderer = aRenderer;
    renderingQueue = queue;
    textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    self = [super initWithFrame:frame];
    if (self) {
        init(self);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    preinit(self);
    self = [super initWithFrame:frame];
    if (self) {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
    preinit(self);
    self = [super initWithCoder:coder];
    if (self) {
        init(self);
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == renderer)
    {
        // Operating in the main queue because this message can be generated in the renderingQueue
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            CGFloat height = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
            CGFloat width = self.bounds.size.width;
            self.contentSize = CGSizeMake(width, (height + textInsets.top + textInsets.bottom) * self.contentScaleFactor);            
        }];
    }
}

#pragma mark -
#pragma mark Rendering Methods

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
        tileViewPool[selected].textInsets = textInsets;
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
    if (ownsRenderer)
        [renderer updateAllText];
}

- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange
{
    if (ownsRenderer)
        [renderer updateTextInLineRange:originalRange toLineRange:newRange];
}


#pragma mark -
#pragma mark Text Renderer Delegate

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
#pragma mark Text Renderer and CodeView String Datasource

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
    if (!ownsRenderer)
        return;
    
    // Will make sure that if no datasource have been set, a default one will be created.
    [self didMoveToSuperview];
    
    if (![self.datasource isKindOfClass:[ECCodeStringDataSource class]])
    {
        [NSException raise:NSInternalInconsistencyException format:@"Trying to set codeview text with textDelegate not self."];
        return;
    }
    
    // Set text
    [(ECCodeStringDataSource *)datasource setString:string];
    [renderer updateAllText];
    
    // Update tiles
    CGRect bounds = self.bounds;
    renderer.wrapWidth = UIEdgeInsetsInsetRect(bounds, self->textInsets).size.width;
    self.contentSize = CGSizeMake(bounds.size.width, (renderer.estimatedHeight + textInsets.top + textInsets.bottom) * self.contentScaleFactor);
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, bounds.size };
    }
    
    [self setNeedsLayout];
}

@end
