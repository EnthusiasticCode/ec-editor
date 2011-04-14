//
//  ECCodeView4.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView4.h"
#import <QuartzCore/QuartzCore.h>
#import "ECMutableTextFileRenderer.h"


#pragma mark -
#pragma mark TextTileView

@interface TextTileView : UIView {
@private
    ECMutableTextFileRenderer *renderer;
}

- (id)initWithTextRenderer:(ECMutableTextFileRenderer *)aRenderer;

@property (nonatomic) NSInteger tileIndex;

@property (nonatomic) CGRect textRect;

- (void)invalidate;

@end

@implementation TextTileView

@synthesize tileIndex, textRect;

- (void)setTextRect:(CGRect)rect
{
    textRect = rect;
    CGSize renderSize = [renderer renderedSizeForTextRect:rect allowGuessedResult:NO];
    renderSize.width = rect.size.width;
    [self setBounds:(CGRect){ CGPointZero, renderSize }];
    [self setNeedsDisplay];
}

- (id)initWithTextRenderer:(ECMutableTextFileRenderer *)aRenderer
{
    if ((self = [super init]))
    {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = YES;
        self.backgroundColor = [UIColor whiteColor];
        renderer = aRenderer;
    }
    return self;
}

- (void)invalidate
{
    tileIndex = -2;
}

- (void)drawRect:(CGRect)rect
{
    // TODO draw in deferred queue
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    {
        CGContextScaleCTM(context, 1, -1);
        [renderer drawTextInRect:textRect inContext:context];
    }
    CGContextRestoreGState(context);
    
    // DEBUG
    [[UIColor redColor] setStroke];
    CGContextSetLineWidth(context, 2);
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, 10, rect.size.height);
    CGContextStrokePath(context);
}

@end

#pragma mark -
#pragma mark ECCodeView4

#define TILEVIEWPOOL_SIZE (3)

@interface ECCodeView4 () {
@private
    ECMutableTextFileRenderer *renderer;
    
    TextTileView* tileViewPool[TILEVIEWPOOL_SIZE];
    CGFloat *tileHeights;
    NSUInteger tileCount;
}

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex;

@end

@implementation ECCodeView4

#pragma mark -
#pragma mark Properties

@synthesize text, textInsets;

- (void)setText:(NSAttributedString *)string
{
    [text release];
    text = [string retain];
    [renderer setString:text];
    
    CGSize renderSize = [renderer renderedSizeForTextRect:CGRectNull allowGuessedResult:YES];
    self.contentSize = renderSize;
    
    free(tileHeights);
    tileCount = ceilf(renderSize.height / self.bounds.size.height);
    tileHeights = (CGFloat *)malloc(sizeof(CGFloat) * tileCount);
    memset(tileHeights, 0, sizeof(CGFloat) * tileCount);
    
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
    }
    
    [self setNeedsLayout];
}

- (void)setFrame:(CGRect)frame
{
    if (text) 
    {
        CGSize renderSize = [renderer renderedSizeForTextRect:CGRectNull allowGuessedResult:YES];
        self.contentSize = renderSize;
        
        free(tileHeights);
        tileCount = ceilf(renderSize.height / frame.size.height);
        tileHeights = (CGFloat *)malloc(sizeof(CGFloat) * tileCount);
        memset(tileHeights, 0, sizeof(CGFloat) * tileCount);
        
        renderer.frameWidth = UIEdgeInsetsInsetRect(frame, self->textInsets).size.width;
        for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
        {
            [tileViewPool[i] invalidate];
        }
    }
    
    [super setFrame:frame];
    [self setNeedsLayout];
}

#pragma mark -
#pragma mark NSObject Methods

static void preinit(ECCodeView4 *self)
{
    self->textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

static void init(ECCodeView4 *self)
{
    self->renderer = [ECMutableTextFileRenderer new];
    self->renderer.frameWidth = UIEdgeInsetsInsetRect(self.bounds, self->textInsets).size.width;
    // TODO pref height max(bounds.widht, bound.height) or screen
    self->renderer.framePreferredHeight = self.bounds.size.height;
    self->renderer.lazyCaching = YES;
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

- (void)dealloc
{
    free(tileHeights);
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
        [tileViewPool[i] release];
    [renderer release];
    [super dealloc];
}

#pragma mark -
#pragma mark Rendering Methods

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex
{
    if (tileIndex >= tileCount)
        return nil;
    
    NSInteger selected = -1;
    // Select free tile
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i) 
    {
        if (tileViewPool[i])
        {
            // Tile already present and ready
            if ([tileViewPool[i] tileIndex] == tileIndex)
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
        tileViewPool[selected] = [[TextTileView alloc] initWithTextRenderer:renderer];
        // TODO remove from self when not displayed
        [self addSubview:tileViewPool[selected]];
    }
    
    tileViewPool[selected].tileIndex = tileIndex;
    
    // Calculate tile text rect
    CGPoint origin = CGPointZero;
    CGSize size = self.bounds.size;
    for (NSInteger i = 0; i < tileIndex; ++i)
        origin.y += tileHeights[i];
    tileViewPool[selected].textRect = (CGRect){ origin, size };
    tileHeights[tileIndex] = tileViewPool[selected].bounds.size.height;
    
    // Adjust content size
    // TODO this fix doesn't kick in fast enought
    if (tileHeights[tileIndex] == 0) 
    {
        self.contentSize = CGSizeMake(self.contentSize.width, origin.y);
        tileCount = tileIndex;
        return nil;
    }
    
    return tileViewPool[selected];
}

- (void)layoutSubviews
{
//    [super layoutSubviews];
    
    if (tileCount == 0)
        return;
    
    // Scrolled content rect
    CGRect contentRect = self.bounds;
    
    // Find first visible tile index
    CGFloat start = 0, end;
    NSUInteger index = 0;
    for (; index < tileCount; ++index)
    {
        end = start + tileHeights[index];
        if (end > contentRect.origin.y)
            break;
        start = end;
    }
    if (index == tileCount)
    {
        index = start = 0;
    }
    
    // Layout first visible tile
    TextTileView *firstTile = [self viewForTileIndex:index];
    firstTile.center = CGPointMake(CGRectGetMidX(contentRect), start + tileHeights[index] / 2.0);
    end = start + firstTile.bounds.size.height;
    
    // Find second visible tile if any
    index++;
    if (index < tileCount)
    {
        TextTileView *secondTile = [self viewForTileIndex:index];
        secondTile.center = CGPointMake(CGRectGetMidX(contentRect), end + tileHeights[index] / 2.0);
        end += tileHeights[index];
    }
}

@end
