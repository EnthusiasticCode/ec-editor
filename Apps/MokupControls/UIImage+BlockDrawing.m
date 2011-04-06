//
//  UIImage+BlockDrawing.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 06/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImage+BlockDrawing.h"
#import <QuartzCore/QuartzCore.h>


@implementation UIImage (BlockDrawing)

+ (UIImage *)imageWithSize:(CGSize)size block:(void(^)(CGContextRef, CGRect))block
{
    // Check parameters
    if (CGSizeEqualToSize(size, CGSizeZero) || !block)
        return nil;
    
    // Render bitmap with block
    CGImageRef bitmap = NULL;
    UIGraphicsBeginImageContext(size);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        block(context, CGRectMake(0, 0, size.width, size.height));        
        bitmap = CGBitmapContextCreateImage(context);
    }
    UIGraphicsEndImageContext();
    
    // Create new image
    UIImage *image = [UIImage imageWithCGImage:bitmap];
    CGImageRelease(bitmap);
    return image;
}

@end
