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
- (id)initWithCodeViewBase:(ECCodeViewBase *)codeView;
- (void)invalidate;
- (void)renderText;

@end

#pragma mark -
#pragma mark Implementations

#pragma mark -
#pragma mark TextTileView

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

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    // Setup renderer wrap with keeping in to account insets and line display
    if (ownsRenderer)
        renderer.wrapWidth = frame.size.width;
    
    self.contentSize = CGSizeMake(frame.size.width, renderer.estimatedHeight * self.contentScaleFactor);
    
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
}

static void init(ECCodeViewBase *self)
{
    if (self->ownsRenderer)
        self->renderer.wrapWidth = self.bounds.size.width;
    [self->renderer addObserver:self forKeyPath:@"estimatedHeight" options:NSKeyValueObservingOptionNew context:nil];
}

- (id)initWithFrame:(CGRect)frame renderer:(ECTextRenderer *)aRenderer renderingQueue:(NSOperationQueue *)queue
{
    ownsRenderer = NO;
    renderer = aRenderer;
    renderingQueue = queue;
    
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
            self.contentSize = CGSizeMake(width, height * self.contentScaleFactor);            
        }];
    }
}

#pragma mark -
#pragma mark Rendering Methods

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
    if (!ownsRenderer)
        return;

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
    ECASSERT([self.datasource isKindOfClass:[ECCodeStringDataSource class]]);
    
    if (!ownsRenderer)
        return;
    
    [(ECCodeStringDataSource *)datasource setString:string];
    
    [renderer updateAllText];
    
    // Update tiles
    CGRect bounds = self.bounds;
    renderer.wrapWidth = bounds.size.width;
    self.contentSize = CGSizeMake(bounds.size.width, renderer.estimatedHeight * self.contentScaleFactor);
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, bounds.size };
    }
    
    [self setNeedsLayout];
}

@end
