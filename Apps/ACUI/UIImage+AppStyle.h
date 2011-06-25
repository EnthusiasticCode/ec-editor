//
//  UIImage+AppStyle.h
//  ACUI
//
//  Created by Nicola Peduzzi on 18/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (AppStyle)

+ (UIImage *)styleProjectImageWithSize:(CGSize)size labelColor:(UIColor *)labelColor;
+ (UIImage *)styleDisclosureImage;
+ (UIImage *)styleAddImage;
+ (UIImage *)styleCloseImageWithColor:(UIColor *)color outlineColor:(UIColor *)outlineColor;

@end
