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
    
    struct {
        unsigned delegateHasColorForRendererLineNumber : 1;
        unsigned reserved : 3;
    } flags;
}

- (void)_setupContentSize;

@end


@implementation ACCodeFileMinimapView

#pragma mark - Properties

@dynamic delegate;
@synthesize renderer;
@synthesize backgroundView;
@synthesize lineHeight, lineDefaultColor, lineShadowColor;

- (void)setDelegate:(id<ACCodeFileMinimapViewDelegate>)aDelegate
{
    if (aDelegate == self.delegate)
        return;
    
    super.delegate = aDelegate;
    flags.delegateHasColorForRendererLineNumber = [self.delegate respondsToSelector:@selector(codeFileMinimapView:colorForRendererLine:number:)];
}

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

- (void)setBackgroundView:(UIView *)_backgroundView
{
    if (backgroundView == _backgroundView)
        return;
    
    [self willChangeValueForKey:@"backgroundView"];
    [backgroundView removeFromSuperview];
    backgroundView = _backgroundView;
    [self insertSubview:backgroundView belowSubview:_contentView];
    [self didChangeValueForKey:@"backgroundView"];
}

- (CGFloat)lineHeight
{
    if (lineHeight < 1)
        lineHeight = 1;
    return lineHeight;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self _setupContentSize];
}

#pragma mark - View Methods

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    
    _contentView = [[ACCodeFileMinimapViewContent alloc] initWithFrame:(CGRect){ CGPointZero, frame.size }];
    _contentView.backgroundColor = [UIColor clearColor];
    __weak ACCodeFileMinimapView *this = self;
    _contentView.customDrawRectBlock = ^(CGRect rect) {
        // This method will be called for every tile of _contentView and rect will be the rect of the tile.
        
        // Setup context and shadow
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (this.lineShadowColor != nil)
            CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 1, this.lineShadowColor.CGColor);
        
        CGContextSetLineWidth(context, this.lineHeight);
        
        __block UIColor *customLineColor, *lastLineColor = this.lineDefaultColor;
        [this.renderer enumerateLinesIntersectingRect:CGRectApplyAffineTransform(rect, this->_toRendererTransform) usingBlock:^(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineYOffset, NSRange stringRange, BOOL *stop) {

            // Draw line block if color changes
            if (this->flags.delegateHasColorForRendererLineNumber)
            {
                customLineColor = [this.delegate codeFileMinimapView:this colorForRendererLine:line number:lineNumber];
                if (customLineColor == nil)
                    customLineColor = this->lineDefaultColor;
                if (customLineColor != lastLineColor)
                {
                    CGContextSetStrokeColorWithColor(context, lastLineColor.CGColor);
                    CGContextStrokePath(context);
                    lastLineColor = customLineColor;
                }
            }
            
            if (line.width < line.height)
                return;
            
            // Position line
            CGFloat lineY = floorf(lineYOffset * this->_toMinimapTransform.a - rect.origin.y) + ((NSInteger)this.lineHeight % 2 ? 0.5 : 0);
            
            // Draw line
            CGContextMoveToPoint(context, 0, lineY);
            CGContextAddLineToPoint(context, line.width * this->_toMinimapTransform.a, lineY);
        }];
        
        CGContextSetStrokeColorWithColor(context, lastLineColor.CGColor);
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (backgroundView)
        backgroundView.frame = (CGRect){ self.contentOffset, self.frame.size };
}

- (void)_setupContentSize
{
    CGRect contentRect = CGRectMake(0, 0,
                                    self.frame.size.width - self.contentInset.left - self.contentInset.right, 
                                    self.renderer.renderHeight);
    if (contentRect.size.width <= 0 || CGRectEqualToRect(_contentView.frame, contentRect))
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