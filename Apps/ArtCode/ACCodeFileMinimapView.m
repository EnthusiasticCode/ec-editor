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
        unsigned delegateHasShouldRendererLineNumberWithColorDecorationDecorationColor : 1;
        unsigned reserved : 3;
    } flags;
}

- (void)_setupContentSize;

@end


@implementation ACCodeFileMinimapView

#pragma mark - Properties

@dynamic delegate;
@synthesize renderer, selectionRectangle, selectionView;
@synthesize backgroundView;
@synthesize lineDecorationInset, lineThickness, lineDefaultColor, lineShadowColor;

- (void)setDelegate:(id<ACCodeFileMinimapViewDelegate>)aDelegate
{
    if (aDelegate == self.delegate)
        return;
    
    super.delegate = aDelegate;
    flags.delegateHasShouldRendererLineNumberWithColorDecorationDecorationColor = [self.delegate respondsToSelector:@selector(codeFileMinimapView:shouldRenderLine:number:withColor:deocration:decorationColor:)];
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

- (UIView *)selectionView
{
    if (!selectionView)
    {
        selectionView = [UIView new];
        selectionView.backgroundColor = [UIColor colorWithRed:0 green:113.0/255.0 blue:188.0/255.0 alpha:0.1];
        selectionView.layer.borderWidth = 1;
        selectionView.layer.borderColor = [UIColor colorWithRed:0 green:113.0/255.0 blue:188.0/255.0 alpha:1].CGColor;
    }
    return selectionView;
}

- (void)setSelectionRectangle:(CGRect)_selectionRectangle
{
    if (CGRectEqualToRect(_selectionRectangle, selectionRectangle))
        return;
    
    [self willChangeValueForKey:@"selectionRectangle"];
    selectionRectangle = _selectionRectangle;
    if (CGRectEqualToRect(selectionRectangle, CGRectNull))
    {
        [selectionView removeFromSuperview];
    }
    else
    {
        if (renderer)
        {
            UIEdgeInsets rendererTextInsets = renderer.textInsets;
            selectionRectangle.size.width -= rendererTextInsets.left + rendererTextInsets.right;
            selectionRectangle.size.height -= rendererTextInsets.top + rendererTextInsets.bottom;
            selectionRectangle.origin.x -= rendererTextInsets.left;
            selectionRectangle.origin.y -= rendererTextInsets.top;
        }
        [self addSubview:self.selectionView];
    }
    
    [self didChangeValueForKey:@"selectionRectangle"];
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

- (CGFloat)lineThickness
{
    if (lineThickness < 1)
        lineThickness = 1;
    return lineThickness;
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
        
        CGContextSetLineWidth(context, this.lineThickness);
        
        CGFloat lindeDecorationInset_2 = this->lineDecorationInset / 2;
        CGFloat lindeDecorationInset_4 = this->lineDecorationInset / 4;
        
        __block UIColor *lastLineColor = this.lineDefaultColor;
        [this.renderer enumerateLinesIntersectingRect:CGRectApplyAffineTransform(rect, this->_toRendererTransform) usingBlock:^(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineYOffset, NSRange stringRange, BOOL *stop) {
            
            ACCodeFileMinimapLineDecoration customDecoration = 0;
            
            // Draw line block if color changes
            if (this->flags.delegateHasShouldRendererLineNumberWithColorDecorationDecorationColor)
            {
                // Retrieve delegate informations for line
                __autoreleasing UIColor *customLineColor = this->lineDefaultColor;
                __autoreleasing UIColor *customDecorationColor = this->lineDefaultColor;
                if (![this.delegate codeFileMinimapView:this shouldRenderLine:line number:lineNumber withColor:&customLineColor deocration:&customDecoration decorationColor:&customDecorationColor])
                    return;
                
                // Render previous placed lines
                if (customDecoration != 0 || customLineColor != lastLineColor)
                {
                    CGContextSetStrokeColorWithColor(context, lastLineColor.CGColor);
                    CGContextStrokePath(context);
                    lastLineColor = customLineColor;
                }
                
                // Set decoration color
                if (customDecoration > 0 && this->lineDecorationInset > 0)
                    CGContextSetFillColorWithColor(context, customDecorationColor.CGColor);
            }
            
            // Position line
            CGFloat lineY = floorf(lineYOffset * this->_toMinimapTransform.a) + ((NSInteger)this->lineThickness % 2 ? 0.5 : 0);
            
            // Render decoration for line
            if (customDecoration > 0 && this->lineDecorationInset > 0)
            {
                switch (customDecoration) {
                    case ACCodeFileMinimapLineDecorationDisc:
                        CGContextAddArc(context, lindeDecorationInset_2, lineY, lindeDecorationInset_4, -M_PI, M_PI, 0);
                        break;
                        
                    case ACCodeFileMinimapLineDecorationSquare:
                    {
                        CGContextAddRect(context, CGRectIntegral(CGRectMake(lindeDecorationInset_4, lineY - lindeDecorationInset_4, lindeDecorationInset_2, lindeDecorationInset_2)));
                        break;
                    }
                        
                    default:
                        break;
                }
                CGContextFillPath(context);
            }
            
            // Draw line
            CGContextMoveToPoint(context, this->lineDecorationInset, lineY);
            CGContextAddLineToPoint(context, this->lineDecorationInset + line.width * this->_toMinimapTransform.a, lineY);
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
    
    if (!CGRectEqualToRect(selectionRectangle, CGRectNull))
    {
        CGRect selectionViewFrame = CGRectApplyAffineTransform(selectionRectangle, _toMinimapTransform);
        selectionViewFrame.origin.x = lineDecorationInset;
        selectionViewFrame.size.width = self.contentSize.width - lineDecorationInset;
        selectionView.frame = CGRectInset(selectionViewFrame, -1, -1);
    }
    
    if (backgroundView)
        backgroundView.frame = (CGRect){ self.contentOffset, self.frame.size };
}

- (void)_setupContentSize
{
    CGRect contentRect = CGRectMake(0, 0,
                                    self.frame.size.width, 
                                    self.renderer.renderHeight);
    if (contentRect.size.width <= 0 || CGRectEqualToRect(_contentView.frame, contentRect))
        return;
    
    CGFloat scale = (contentRect.size.width - self.lineDecorationInset - self.contentInset.left - self.contentInset.right) / self.renderer.renderWidth;
    contentRect.size.height *= scale;
    contentRect = CGRectIntegral(contentRect);
    
    _toMinimapTransform = CGAffineTransformMakeScale(scale, scale);
    _toRendererTransform = CGAffineTransformInvert(_toMinimapTransform);
    
    self.contentSize = (CGSize){ (contentRect.size.width - self.contentInset.left - self.contentInset.right), contentRect.size.height };

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