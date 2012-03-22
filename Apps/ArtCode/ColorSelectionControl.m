//
//  ColorSelectionControl.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ColorSelectionControl.h"
#import "UIColor+AppStyle.h"

@implementation ColorSelectionControl

@synthesize colors, colorCellsMargin, columns, rows, selectedColor, userInfo;

- (void)setColors:(NSArray *)array
{
    colors = array;
    
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    [colors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger idx, BOOL *stop) {
        CALayer *layer = [CALayer layer];
        layer.backgroundColor = color.CGColor;
        layer.zPosition = idx;
        [self.layer addSublayer:layer]; 
    }];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    CGRect colorBounds = self.bounds;
    colorBounds.size.width = (colorBounds.size.width - ((columns - 1) * colorCellsMargin)) / columns;
    colorBounds.size.height = (colorBounds.size.height - ((rows - 1) * colorCellsMargin)) / rows;

    NSUInteger itemPerRow = [colors count] / rows;
    [self.layer.sublayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        CGRect layerFrame = colorBounds;
        layerFrame.origin.x = (layerFrame.size.width + colorCellsMargin) * (idx % columns);
        layerFrame.origin.y = (layerFrame.size.height + colorCellsMargin) * (idx / itemPerRow);
        layer.frame = layerFrame;
    }];
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    CGPoint location = [[[event touchesForView:self] anyObject] locationInView:self];
    CGSize boundsSize = self.bounds.size;
    
    NSUInteger r = (location.y * rows / boundsSize.height);
    NSUInteger c = (location.x * columns / boundsSize.width);
    NSUInteger colorIndex = columns * r + c;
    
    ASSERT(colorIndex < [colors count]);
    
    selectedColor = [colors objectAtIndex:colorIndex];
    
    [super sendAction:action to:target forEvent:event];
}

static void _init(ColorSelectionControl *self)
{
    if (self->rows != 0)
        return;
    
    self.colorCellsMargin = 2;
    self.columns = 3;
    self.rows = 2;
    self.colors = [NSArray arrayWithObjects:
                   [UIColor colorWithRed:255./255. green:106./255. blue:89./255. alpha:1], 
                   [UIColor colorWithRed:255./255. green:184./255. blue:62./255. alpha:1], 
                   [UIColor colorWithRed:237./255. green:233./255. blue:68./255. alpha:1],
                   [UIColor colorWithRed:168./255. green:230./255. blue:75./255. alpha:1],
                   [UIColor colorWithRed:93./255. green:157./255. blue:255./255. alpha:1],
                   [UIColor styleForegroundColor], nil];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _init(self);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    _init(self);
    return self;
}

@end
