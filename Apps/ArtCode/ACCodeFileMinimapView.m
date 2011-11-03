//
//  ACCodeFileMinimapView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileMinimapView.h"
#import <ECUIKit/ECTextRenderer.h>
#import <QuartzCore/QuartzCore.h>

static const void *rendererContext;
#define TILE_HEIGHT 400


@interface ACCodeFileMinimapViewContent : UIView
@property (copy, nonatomic) void (^customDrawRectBlock)(CGRect rect);
@end


@interface ACCodeFileMinimapView () {
@private
    ACCodeFileMinimapViewContent *_contentView;
    CGAffineTransform _toMinimapTransform;
    CGAffineTransform _toRendererTransform;
}

- (void)_setupContentSize;

@end


@implementation ACCodeFileMinimapView

#pragma mark - Properties

@synthesize renderer, rendererMinimumLineWidth;
@synthesize backgroundView;
@synthesize lineHeight, lineGap, lineColor, lineShadowColor;

- (void)setRenderer:(ECTextRenderer *)aRenderer
{
    if (aRenderer == renderer)
        return;
    
    [self willChangeValueForKey:@"renderer"];
    [renderer removeObserver:self forKeyPath:@"renderHeight" context:&rendererContext];
    renderer = aRenderer;
    [renderer addObserver:self forKeyPath:@"renderHeight" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&rendererContext];
    [self didChangeValueForKey:@"renderer"];
}

- (CGFloat)lineHeight
{
    if (lineHeight < 1)
        lineHeight = 1;
    return lineHeight;
}

- (CGFloat)lineGap
{
    if (lineGap < 1)
        lineGap = 1;
    return lineGap;
}

#pragma mark - View Methods

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    
    _contentView = [[ACCodeFileMinimapViewContent alloc] initWithFrame:(CGRect){ CGPointZero, frame.size }];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _contentView.backgroundColor = [UIColor clearColor];
    __weak ACCodeFileMinimapView *this = self;
    _contentView.customDrawRectBlock = ^(CGRect rect) {
        // This method will be called for every tile of _contentView and rect will be the rect of the tile.
        
        // Setup context and shadow
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (this.lineShadowColor != nil)
            CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 0, this.lineShadowColor.CGColor);
        
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(context, this.lineHeight);
        
        CGFloat gap = this.lineHeight + this.lineGap;
        __block CGFloat lineY = CGFLOAT_MAX;
        [this.renderer enumerateLinesIntersectingRect:CGRectApplyAffineTransform(rect, this->_toRendererTransform) usingBlock:^(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineYOffset, NSRange stringRange, BOOL *stop) {
            if (lineY == CGFLOAT_MAX)
                lineY = floorf(lineYOffset * this->_toMinimapTransform.a - rect.origin.y) + ((NSInteger)this.lineHeight % 2 ? 0.5 : 0);
            if (line.width >= this->rendererMinimumLineWidth)
            {
                CGContextMoveToPoint(context, 0, lineY);
                CGContextAddLineToPoint(context, line.width * this->_toMinimapTransform.a, lineY);
            }
            lineY += gap;
        }];
        
        CGContextStrokePath(context);
    };
    [self addSubview:_contentView];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &rendererContext)
    {
        [self _setupContentSize];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)_setupContentSize
{
    CGRect contentRect = CGRectMake(0, 0,
                                    self.frame.size.width - self.contentInset.left - self.contentInset.right, 
                                    self.renderer.renderHeight);
    if (contentRect.size.width <= 0)
        return;
    
    CGFloat scale = contentRect.size.width / self.renderer.renderWidth;
    contentRect.size.height *= scale;
    contentRect = CGRectIntegral(contentRect);
    
    _toMinimapTransform = CGAffineTransformMakeScale(scale, scale);
    _toRendererTransform = CGAffineTransformInvert(_toMinimapTransform);
    
    self.contentSize = contentRect.size;

    _contentView.frame = contentRect;
    [(CATiledLayer *)_contentView.layer setTileSize:CGSizeMake(contentRect.size.width, TILE_HEIGHT)];
    [_contentView setNeedsDisplay];
}

@end


@implementation ACCodeFileMinimapViewContent

@synthesize customDrawRectBlock;

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (void)drawRect:(CGRect)rect
{
    if (customDrawRectBlock)
        customDrawRectBlock(rect);
}

@end