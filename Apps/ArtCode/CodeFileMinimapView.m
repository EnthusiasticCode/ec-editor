//
//  CodeFileMinimapView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFileMinimapView.h"
#import "TextRenderer.h"
#import <QuartzCore/QuartzCore.h>

static const void *rendererContext;
#define TILE_HEIGHT 400


@interface CodeFileMinimapViewContent : UIView
@property (copy, nonatomic) void (^customDrawRectBlock)(CGRect rect);
@end


@interface CodeFileMinimapView () {
@private
  CodeFileMinimapViewContent *_contentView;
  
  CGAffineTransform _toMinimapTransform;
  CGAffineTransform _toRendererTransform;
  CGSize _renderSize;
  
  struct {
    unsigned delegateHasShouldRendererLineNumberRangeWithColorDecorationDecorationColor : 1;
    unsigned delegateHasShouldChangeSelectionRectangle : 1;
    unsigned reserved : 2;
  } flags;
}

- (void)_handleGestureMinimapTap:(UITapGestureRecognizer *)recognizer;

@end


@implementation CodeFileMinimapView

#pragma mark - Properties

@dynamic delegate;
@synthesize renderer, selectionRectangle, selectionView;
@synthesize backgroundView;
@synthesize lineDecorationInset, lineThickness, lineDefaultColor, lineShadowColor;

- (void)setDelegate:(id<CodeFileMinimapViewDelegate>)aDelegate
{
  if (aDelegate == self.delegate)
    return;
  
  super.delegate = aDelegate;
  flags.delegateHasShouldRendererLineNumberRangeWithColorDecorationDecorationColor = [self.delegate respondsToSelector:@selector(codeFileMinimapView:shouldRenderLine:number:range:withColor:decoration:decorationColor:)];
  flags.delegateHasShouldChangeSelectionRectangle = [self.delegate respondsToSelector:@selector(codeFileMinimapView:shouldChangeSelectionRectangle:)];
}

- (void)setRenderer:(TextRenderer *)aRenderer
{
  if (aRenderer == renderer)
    return;
  
  [renderer removeObserver:self forKeyPath:@"renderWidth" context:&rendererContext];
  [renderer removeObserver:self forKeyPath:@"renderHeight" context:&rendererContext];
  renderer = aRenderer;
  [renderer addObserver:self forKeyPath:@"renderWidth" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&rendererContext];
  [renderer addObserver:self forKeyPath:@"renderHeight" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&rendererContext];
}

- (UIView *)selectionView
{
  if (!selectionView)
  {
    selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = [UIColor colorWithRed:0 green:113.0/255.0 blue:188.0/255.0 alpha:0.1];
    selectionView.layer.borderWidth = 1;
    selectionView.layer.borderColor = [UIColor colorWithRed:0 green:113.0/255.0 blue:188.0/255.0 alpha:1].CGColor;
  }
  return selectionView;
}

- (void)setSelectionRectangle:(CGRect)_selectionRectangle
{
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
      selectionRectangle.size.height -= rendererTextInsets.top + rendererTextInsets.bottom;
      selectionRectangle.origin.y -= rendererTextInsets.top;
    }
    [self addSubview:self.selectionView];
    //        [self scrollRectToVisible:(CGRect) { self.selectionView.frame.origin, { 1, 1 }} animated:YES];
  }
  
}

- (void)setBackgroundView:(UIView *)_backgroundView
{
  if (backgroundView == _backgroundView)
    return;
  
  [backgroundView removeFromSuperview];
  backgroundView = _backgroundView;
  [self insertSubview:backgroundView belowSubview:_contentView];
}

- (CGFloat)lineThickness
{
  if (lineThickness < 1)
    lineThickness = 1;
  return lineThickness;
}

#pragma mark - View Methods

- (id)initWithFrame:(CGRect)frame
{
  if (!(self = [super initWithFrame:frame]))
    return nil;
  
  _contentView = [[CodeFileMinimapViewContent alloc] initWithFrame:(CGRect){ CGPointZero, frame.size }];
  _contentView.backgroundColor = UIColor.clearColor;
  __weak CodeFileMinimapView *this = self;
  _contentView.customDrawRectBlock = ^(CGRect rect) {
    CodeFileMinimapView *strongSelf = this;
    if (!strongSelf) {
      return;
    }
    
    // This method will be called for every tile of _contentView and rect will be the rect of the tile.
    // Setup context and shadow
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (this.lineShadowColor != nil)
      CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 1, this.lineShadowColor.CGColor);
    
    CGContextSetLineWidth(context, this.lineThickness);
    
    CGFloat lindeDecorationInset_2 = strongSelf->lineDecorationInset / 2;
    CGFloat lindeDecorationInset_4 = strongSelf->lineDecorationInset / 4;
    
    __block UIColor *lastLineColor = this.lineDefaultColor;
    [this.renderer enumerateLinesIntersectingRect:CGRectApplyAffineTransform(rect, strongSelf->_toRendererTransform) usingBlock:^(TextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineYOffset, NSRange stringRange, BOOL *stop) {
      
      CodeFileMinimapLineDecoration customDecoration = 0;
      
      // Draw line block if color changes
      if (strongSelf->flags.delegateHasShouldRendererLineNumberRangeWithColorDecorationDecorationColor)
      {
        // Retrieve delegate informations for line
        __autoreleasing UIColor *customLineColor = strongSelf->lineDefaultColor;
        __autoreleasing UIColor *customDecorationColor = strongSelf->lineDefaultColor;
        if (![this.delegate codeFileMinimapView:this shouldRenderLine:line number:lineNumber range:stringRange withColor:&customLineColor decoration:&customDecoration decorationColor:&customDecorationColor])
          return;
        
        // Render previous placed lines
        if (customDecoration != 0 || customLineColor != lastLineColor)
        {
          CGContextSetStrokeColorWithColor(context, lastLineColor.CGColor);
          CGContextStrokePath(context);
          lastLineColor = customLineColor;
        }
        
        // Set decoration color
        if (customDecoration > 0 && strongSelf->lineDecorationInset > 0)
          CGContextSetFillColorWithColor(context, customDecorationColor.CGColor);
      }
      
      // Position line
      CGFloat lineY = floorf(lineYOffset * strongSelf->_toMinimapTransform.a) + ((NSInteger)strongSelf->lineThickness % 2 ? 0.5 : 0);

      // Render decoration for line
      if (customDecoration > 0 && strongSelf->lineDecorationInset > 0)
      {
        switch (customDecoration) {
          case CodeFileMinimapLineDecorationDisc:
            CGContextAddArc(context, lindeDecorationInset_2, lineY, lindeDecorationInset_4, -M_PI, M_PI, 0);
            break;
            
          case CodeFileMinimapLineDecorationSquare:
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
      CGContextMoveToPoint(context, strongSelf->lineDecorationInset, lineY);
      CGContextAddLineToPoint(context, strongSelf->lineDecorationInset + line.width * strongSelf->_toMinimapTransform.a, lineY);
    }];
    
    CGContextSetStrokeColorWithColor(context, lastLineColor.CGColor);
    CGContextStrokePath(context);
  };
  [self addSubview:_contentView];
  
  [_contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureMinimapTap:)]];
  
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context == &rendererContext)
  {
    CGSize newRenderSize = CGSizeMake(self.renderer.renderWidth, self.renderer.renderHeight);
    if (CGSizeEqualToSize(_renderSize, newRenderSize))
      return;
    _renderSize = newRenderSize;
    
    CGRect contentRect = CGRectMake(0, 0,
                                    self.frame.size.width, 
                                    _renderSize.height);
    if (contentRect.size.width <= 0 || CGRectEqualToRect(_contentView.frame, contentRect))
      return;
    
    CGFloat scale = (contentRect.size.width - self.lineDecorationInset - self.contentInset.left - self.contentInset.right) / _renderSize.width;
    contentRect.size.height *= scale;
    contentRect = CGRectIntegral(contentRect);
    
    _toMinimapTransform = CGAffineTransformMakeScale(scale, scale);
    _toRendererTransform = CGAffineTransformInvert(_toMinimapTransform);
    
    self.contentSize = (CGSize){ (contentRect.size.width - self.contentInset.left - self.contentInset.right), contentRect.size.height };
    
    _contentView.frame = contentRect;
    [(CATiledLayer *)_contentView.layer setTileSize:CGSizeMake(contentRect.size.width, TILE_HEIGHT)];
    [_contentView setNeedsDisplay];
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay];
  [_contentView setNeedsDisplay];
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

- (void)scrollToSelection
{
  CGRect selectionViewFrame = CGRectApplyAffineTransform(selectionRectangle, _toMinimapTransform);
  selectionViewFrame.size.width = 1;
  [self scrollRectToVisible:selectionViewFrame animated:YES];
}

#pragma mark - Private Methods

- (void)_handleGestureMinimapTap:(UITapGestureRecognizer *)recognizer
{
  CGPoint tapPoint = CGPointApplyAffineTransform([recognizer locationInView:_contentView], _toRendererTransform);
  CGRect selection = selectionRectangle;
  selection.origin.y = tapPoint.y - selection.size.height / 2;
  
  if (flags.delegateHasShouldChangeSelectionRectangle && ![self.delegate codeFileMinimapView:self shouldChangeSelectionRectangle:selection])
    return;
  
  self.selectionRectangle = selection;
}

@end


@implementation CodeFileMinimapViewContent

@synthesize customDrawRectBlock;

+ (Class)layerClass
{
  return CATiledLayer.class;
}

- (void)drawRect:(CGRect)rect
{
  if (customDrawRectBlock)
    customDrawRectBlock(rect);
}

@end