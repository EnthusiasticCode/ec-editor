//
//  UIImage+AppStyle.h
//  ACUI
//
//  Created by Nicola Peduzzi on 18/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (AppStyle)

/// Create a resizable image with a rounded rectangle of corner radius 3, a border
/// of 1 pixel insetted as specified. The arrow size can make the image have an
/// arrow either on the right if positive or left if negative.
+ (UIImage *)styleBackgroundImageWithColor:(UIColor *)color 
                               borderColor:(UIColor *)borderColor 
                                    insets:(UIEdgeInsets)borderInsets 
                                 arrowSize:(CGSize)arrowSize
                           roundingCorners:(UIRectCorner)cornersToRound;

+ (UIImage *)styleBackgroundImageWithColor:(UIColor *)color borderColor:(UIColor *)borderColor;

/// Icon of a document with a bookmark label used to represent projects with style 
/// foreground color and shadow.
+ (UIImage *)styleProjectImageWithSize:(CGSize)size labelColor:(UIColor *)labelColor;

/// Icon of a document with 1 pixel outline and colored inside.
/// A label may also be applied to indicate document extension.
+ (UIImage *)styleDocumentImageWithSize:(CGSize)size color:(UIColor *)color text:(NSString *)text;

/// Table disclosure arrow with style foreground color and shadow. This image is cached.
+ (UIImage *)styleTableDisclosureImage;

/// Image of a triangle poinging in the direction of its orientation.
+ (UIImage *)styleDisclosureArrowImageWithOrientation:(UIImageOrientation)orientation color:(UIColor *)color;

/// Image of a + with style foreground color and shadow.
+ (UIImage *)styleAddImageWithColor:(UIColor *)color shadowColor:(UIColor *)shadowColor;

/// Image of an X. This image can have a required background and outline color. 
/// The outline will look like a border.
+ (UIImage *)styleCloseImageWithColor:(UIColor *)color outlineColor:(UIColor *)outlineColor;

/// Produce a rounded rect 14x14 image with the given color and white letter over it.
+ (UIImage *)styleSymbolImageWithColor:(UIColor *)color letter:(NSString *)letter;

+ (UIImage *)styleSearchIcon;

@end
