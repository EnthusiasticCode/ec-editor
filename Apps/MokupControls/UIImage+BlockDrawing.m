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
    
    // Generating bitmap context
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGSize pixelSize = CGSizeMake(size.width * screenScale, size.height * screenScale);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, pixelSize.width, pixelSize.height, 8, 4*pixelSize.width, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    // Render bitmap with block
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -pixelSize.height);
    block(context, CGRectMake(0, 0, pixelSize.width, pixelSize.height));
    
    // Create bitmap
    CGImageRef bitmap = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    // Create new image
    UIImage *image = [UIImage imageWithCGImage:bitmap];
    CGImageRelease(bitmap);
    return image;
}

@end
