//
//  UIFont+Style.m
//  ACUI
//
//  Created by Nicola Peduzzi on 18/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIFont+AppStyle.h"

@implementation UIFont (AppStyle)

+ (UIFont *)styleFontWithSize:(CGFloat)size
{
    static CGFloat lastSize = 0;
    static UIFont *lastSizeFont = nil;
    
    if (size == lastSize)
        return lastSizeFont;
    
    lastSize = size;
    lastSizeFont = [UIFont fontWithName:@"Helvetica-Bold" size:size];
    
    return lastSizeFont;
}

@end
