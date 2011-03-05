//
//  ECOverlayStyle.h
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^BuildOverlayPathForRectBlock)(CGMutablePathRef result, CGRect rect, UIColor *color, NSDictionary *attr);

@interface ECTextOverlayStyle : NSObject {
@protected
    NSString *name;
    UIColor *color;
    UIColor *alternativeColor;
    NSDictionary *attributes;
    BuildOverlayPathForRectBlock pathBlock;
}

/// The name of the overlay style.
@property (nonatomic, copy) NSString *name;

/// A color associated with the overlay.
@property (nonatomic, retain) UIColor *color;

/// An alternative color associated with the overlay.
@property (nonatomic, retain) UIColor *alternativeColor;

/// A dictionary of additional, custom attributes.
@property (nonatomic, copy) NSDictionary *attributes;

/// The block to use to draw the overlay in the given rect expressed in given conetxt coordinates.
@property (nonatomic, copy) BuildOverlayPathForRectBlock pathBlock;

/// Initialize an new style with all its attributes.
- (id)initWithName:(NSString *)aName color:(UIColor *)aColor alternativeColor:(UIColor *)anAlternative attributes:(NSDictionary *)anyAttrib pathBlock:(BuildOverlayPathForRectBlock)aBlock;

/// Build a given path to conform to the overlay style in the given rect.
- (void)buildOverlayPath:(CGMutablePathRef)path forRect:(CGRect)rect alternative:(BOOL)isAlternative;

/// Create a simple overlay style that will result in a rectangle.
+ (id)highlightTextOverlayStyleWithName:(NSString *)name color:(UIColor *)color alternativeColor:(UIColor *)alternative cornerRadius:(CGFloat)radius;

/// Create an underline overlay. 
+ (id)underlineTextOverlayStyleWithName:(NSString *)name color:(UIColor *)color alternativeColor:(UIColor *)alternative thickness:(CGFloat)thickness shape:(NSString *)shape;

@end
