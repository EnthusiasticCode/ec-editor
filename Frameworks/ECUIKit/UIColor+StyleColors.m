//
//  UIColor+StyleColors.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIColor+StyleColors.h"


@implementation UIColor (StyleColors)

+ (UIColor *)styleBackgroundColor
{
    return [UIColor colorWithWhite:0.90 alpha:1.0];
}

+ (UIColor *)styleBackgroundShadowColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)styleHighlightColor
{
    return [UIColor colorWithWhite:0.70 alpha:1.0];
}

+ (UIColor *)styleAlternateBackgroundColor
{
//    return [UIColor colorWithRed:62.0/255.0 green:60.0/255.0 blue:60.0/255.0 alpha:1.0];
    return [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
}

+ (UIColor *)styleForegroundColor
{
    return [UIColor colorWithWhite:0.16 alpha:1.0];
}

+ (UIColor *)styleForegroundShadowColor
{
//    return [UIColor colorWithRed:205.0/255.0 green:202.0/255.0 blue:200.0/255.0 alpha:0.3];
    return [[UIColor whiteColor] colorWithAlphaComponent:0.3];
}

+ (UIColor *)styleThemeColorOne
{
    return [UIColor colorWithRed:98.0/255.0 green:157.0/255.0 blue:222.0/255.0 alpha:1.0];
}

@end
