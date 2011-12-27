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

/// Icon of a label similar to the one on the project image.
+ (UIImage *)styleProjectLabelImageWithSize:(CGSize)size color:(UIColor *)color;

/// Icon of a document with 1 pixel outline and colored inside.
/// A label may also be applied to indicate document extension.
+ (UIImage *)styleDocumentImageWithSize:(CGSize)size color:(UIColor *)color text:(NSString *)text;

/// Icon of a group.
+ (UIImage *)styleGroupImageWithSize:(CGSize)size;

/// Table disclosure arrow.
+ (UIImage *)styleTableDisclosureImageWithColor:(UIColor *)color shadowColor:(UIColor *)shadowColor;

/// Image of a triangle poinging in the direction of its orientation.
+ (UIImage *)styleDisclosureArrowImageWithOrientation:(UIImageOrientation)orientation color:(UIColor *)color;

/// Image of a + with style foreground color and shadow.
+ (UIImage *)styleAddImageWithColor:(UIColor *)color shadowColor:(UIColor *)shadowColor;

/// Image of an X. This image can have a required background and outline color. 
/// The outline will look like a border.
+ (UIImage *)styleCloseImageWithColor:(UIColor *)color outlineColor:(UIColor *)outlineColor shadowColor:(UIColor *)shadowColor;

/// Produce a rounded rect 14x14 image with the given color and white letter over it.
+ (UIImage *)styleSymbolImageWithColor:(UIColor *)color letter:(NSString *)letter;

/// Icon 16x16+shadow of a magnifying glass.
+ (UIImage *)styleSearchIconWithColor:(UIColor *)color shadowColor:(UIColor *)shadowColor;

/// An image to be used in a table view cell check mark. Cached.
+ (UIImage *)styleCheckMarkImage;

/// An image to be used as a table reorder control. Cached.
+ (UIImage *)styleReorderControlImage;

/// An image to be used as a table delete activation control. Cached.
+ (UIImage *)styleDeleteActivationImage;

@end
