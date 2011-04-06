//
//  UIImage+BlockDrawing.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 06/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (BlockDrawing)

/// Creates and returns an image object of the specifed size that uses the specified block for rendering.
/// The block is responsable to draw the bitmap data in the given context within the given rect.
+ (UIImage *)imageWithSize:(CGSize)size block:(void(^)(CGContextRef ctx, CGRect rect))block;

@end
