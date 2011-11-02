//
//  ACCodeFileMinimapView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileMinimapView.h"
#import <QuartzCore/QuartzCore.h>

#define LINES_PER_TILE 200

@interface ACCodeFileMinimapViewContent : UIView
@property (copy, nonatomic) void (^customDrawRectBlock)(CGRect rect);
@end

@implementation ACCodeFileMinimapView {
    ACCodeFileMinimapViewContent *_contentView;
}

#pragma mark - Properties

@synthesize dataSource;
@synthesize backgroundView;
@synthesize lineHeight, lineGap, lineColor, lineShadowColor;

- (void)setDataSource:(id<ACCodeFileMinimapViewDataSource>)aDataSource
{
    if (aDataSource == dataSource)
        return;
    
    [self willChangeValueForKey:@"dataSource"];
    dataSource = aDataSource;
    [self reloadAllData];
    [self didChangeValueForKey:@"dataSource"];
}

- (CGFloat)lineHeight
{
    if (lineHeight < 1)
        lineHeight = 1;
    return lineHeight;
}

- (void)setLineHeight:(CGFloat)height
{
    if (height == lineHeight)
        return;
    
    [self willChangeValueForKey:@"lineHeight"];
    lineHeight = height;
    [self reloadAllData];
    [self didChangeValueForKey:@"lineHeight"];
}

- (CGFloat)lineGap
{
    if (lineGap < 1)
        lineGap = 1;
    return lineGap;
}

- (void)setLineGap:(CGFloat)gap
{
    if (gap == lineGap)
        return;
    
    [self willChangeValueForKey:@"lineGap"];
    lineGap = gap;
    [self reloadAllData];
    [self didChangeValueForKey:@"lineGap"];
}

#pragma mark - View Methods

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
        return nil;
    
    _contentView = [[ACCodeFileMinimapViewContent alloc] initWithFrame:(CGRect){ CGPointZero, frame.size }];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    __weak ACCodeFileMinimapView *this = self;
    _contentView.customDrawRectBlock = ^(CGRect rect) {
        // This method will be called for every tile of _contentView and rect will be the rect of the tile.
        // Calculate index of first line to render and validate it
        CGFloat totalLineHeight = this.lineHeight + this.lineGap;
        NSUInteger lineIndex = rect.origin.y * totalLineHeight;
        NSUInteger lineCount = [this.dataSource numberOfLinesForCodeFileMinimapView:this];
        if (lineIndex >= lineCount)
            return;
        
        // Calculate number of lines to render
        lineCount = MIN((lineCount - lineIndex), rect.size.height * totalLineHeight);
        
        // Setup shadow
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (this.lineShadowColor != nil)
            CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 0, this.lineShadowColor.CGColor);
        
        // Render lines
        UIColor *color, *lastColor = this.lineColor;
        CGFloat lineOffset = (fabsf(this.lineHeight) != this.lineHeight || (NSInteger)this.lineHeight % 2) ? 0 : 0.5;
        CGPoint lineEndPoint;
        for (; lineIndex < lineCount; ++lineIndex)
        {
            // Compute line width and color
            color = this.lineColor;
            lineEndPoint = CGPointMake([this.dataSource codeFileMinimapView:this lenghtOfLineAtIndex:lineIndex applyColor:&color] * rect.size.width, lineIndex * totalLineHeight + lineOffset);
            
            // Draw previous path of lines if with different color
            if (lastColor != color)
            {
                CGContextSetStrokeColorWithColor(context, lastColor.CGColor);
                CGContextStrokePath(context);
                lastColor = color;
            }
            
            // Add line to context path
            CGContextMoveToPoint(context, 0, lineEndPoint.y);
            CGContextAddLineToPoint(context, lineEndPoint.x, lineEndPoint.y);
        }
        
        // Rendering last line group
        CGContextSetStrokeColorWithColor(context, lastColor.CGColor);
        CGContextStrokePath(context);
    };
    [self addSubview:_contentView];
    
    return self;
}

#pragma mark - Data Methods

- (void)reloadAllData
{
    ECASSERT(dataSource != nil);
    
    self.contentSize = CGSizeMake(UIEdgeInsetsInsetRect(self.frame, self.contentInset).size.width, [self.dataSource numberOfLinesForCodeFileMinimapView:self] * (self.lineHeight + self.lineGap));
    [(CATiledLayer *)_contentView.layer setTileSize:CGSizeMake(self.contentSize.width, LINES_PER_TILE * (self.lineHeight + self.lineGap))];
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