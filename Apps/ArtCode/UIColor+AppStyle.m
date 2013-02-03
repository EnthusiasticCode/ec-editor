//
//  UIColor+StyleColors.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIColor+AppStyle.h"


@implementation UIColor (AppStyle)

#define RETURN_CACHED_COLOR(nam,clr)  \
static UIColor *_##nam = nil; \
if (!_##nam) _##nam = clr;    \
return _##nam

+ (UIColor *)styleBackgroundColor
{
  RETURN_CACHED_COLOR(styleBackgroundColor, 
                      [UIColor colorWithWhite:0.90 alpha:1.0]);
}

+ (UIColor *)styleBackgroundShadowColor
{
  RETURN_CACHED_COLOR(styleBackgroundShadowColor, 
                      UIColor.whiteColor);
}

+ (UIColor *)styleHighlightColor
{
  RETURN_CACHED_COLOR(styleHighlightColor, 
                      [UIColor colorWithWhite:0.70 alpha:1.0]);
}

+ (UIColor *)styleAlternateBackgroundColor
{
  RETURN_CACHED_COLOR(styleAlternateBackgroundColor, 
                      [UIColor colorWithWhite:0.80 alpha:1.0]);
}

+ (UIColor *)styleForegroundColor
{
  RETURN_CACHED_COLOR(styleForegroundColor, 
                      [UIColor colorWithWhite:0.10 alpha:1.0]);
}

+ (UIColor *)styleForegroundShadowColor
{
  RETURN_CACHED_COLOR(styleForegroundShadowColor, 
                      [UIColor colorWithWhite:1 alpha:0.3]);
}

+ (UIColor *)styleThemeColorOne
{
  RETURN_CACHED_COLOR(styleThemeColorOne, 
                      [UIColor colorWithRed:98.0/255.0 green:157.0/255.0 blue:222.0/255.0 alpha:1.0]);
}

+ (UIColor *)styleDeleteColor
{
  RETURN_CACHED_COLOR(styleDeleteColor, 
                      [UIColor colorWithRed:200.0/255.0 green:8.0/255.0 blue:21.0/255.0 alpha:1.0]);
}

@end
