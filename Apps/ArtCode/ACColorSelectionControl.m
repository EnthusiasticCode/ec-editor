//
//  ACColorSelectionControl.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ACColorSelectionControl.h"

@implementation ACColorSelectionControl

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
    
    ECASSERT(colorIndex < [colors count]);
    
    selectedColor = [colors objectAtIndex:colorIndex];
    
    [super sendAction:action to:target forEvent:event];
}


@end
