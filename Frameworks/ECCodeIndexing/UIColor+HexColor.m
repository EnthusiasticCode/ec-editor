//
//  UIColor+HexColor.m
//  ECCodeIndexing
//
//  Created by Nicola Peduzzi on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIColor+HexColor.h"

@implementation UIColor (HexColor)

+ (UIColor *)colorWithHexString:(NSString *)string
{
    if (string == nil || ![string hasPrefix:@"#"])
        return nil;
    
    NSString *rString = nil, *gString = nil, *bString = nil, *aString = nil;
    if (string.length == 7)
    {
        rString = [string substringWithRange:NSMakeRange(1, 2)];
        gString = [string substringWithRange:NSMakeRange(3, 2)];
        bString = [string substringWithRange:NSMakeRange(5, 2)];
    }
    else if (string.length == 9)
    {
        rString = [string substringWithRange:NSMakeRange(1, 2)];
        gString = [string substringWithRange:NSMakeRange(3, 2)];
        bString = [string substringWithRange:NSMakeRange(5, 2)];
        aString = [string substringWithRange:NSMakeRange(7, 2)];
    }
    else if (string.length == 4)
    {
        rString = [string substringWithRange:NSMakeRange(1, 1)];
        gString = [string substringWithRange:NSMakeRange(2, 1)];
        bString = [string substringWithRange:NSMakeRange(3, 1)];
    }
    
    ECASSERT(rString != nil);
    
    unsigned int r, g, b, a = 255;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    if (aString != nil)
        [[NSScanner scannerWithString:aString] scanHexInt:&a];
    
    return [UIColor colorWithRed:(CGFloat)r / 255.0f 
                           green:(CGFloat)g / 255.0f 
                            blue:(CGFloat)b / 255.0f 
                           alpha:(CGFloat)a / 255.0f];
}

@end
