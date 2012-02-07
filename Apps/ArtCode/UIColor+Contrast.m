//
//  UIColor+Contrast.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 07/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIColor+Contrast.h"

@implementation UIColor (Contrast)

- (UIColor *)colorByIncreasingContrast:(CGFloat)value
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];

    CGFloat brightness = ((r * 299.0) + (g * 587.0) + (b * 114.0)) / 1000.0;
    if (brightness >= 0.5)
        value = -value;
    
    return [UIColor colorWithRed:r + value green:g + value blue:b + value alpha:a];
}

@end
