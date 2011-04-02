//
//  ECOverlayStyle.h
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECRectSet.h"


typedef void (^BuildOverlayPathForRectBlock)(CGMutablePathRef result, ECRectSet *rects, NSDictionary *attr);

@interface ECTextOverlayStyle : NSObject {
@protected
    NSString *name;
    UIColor *color;
    NSDictionary *attributes;
    BuildOverlayPathForRectBlock pathBlock;
}

#pragma mark Overlay Styling Attributes

/// The name of the overlay style.
@property (nonatomic, copy) NSString *name;

/// A color associated with the overlay.
@property (nonatomic, retain) UIColor *color;

/// A color to use for the overlay stroke.
@property (nonatomic, retain) UIColor *strokeColor;

/// A dictionary of additional, custom attributes.
@property (nonatomic, copy) NSDictionary *attributes;

/// The block to use to draw the overlay in the given rect expressed in given conetxt coordinates.
@property (nonatomic, copy) BuildOverlayPathForRectBlock pathBlock;

/// Indicate if the style is supposed to be placed under the text.
@property (nonatomic, getter = isBelowText) BOOL belowText;

#pragma mark Overlay Style Creation

/// Initialize an new style with all its attributes.
- (id)initWithName:(NSString *)aName color:(UIColor *)aColor attributes:(NSDictionary *)anyAttrib pathBlock:(BuildOverlayPathForRectBlock)aBlock;

/// Create a simple overlay style that will result in a rectangle.
+ (id)highlightTextOverlayStyleWithName:(NSString *)name color:(UIColor *)color cornerRadius:(CGFloat)radius;

/// Create an underline overlay. 
+ (id)underlineTextOverlayStyleWithName:(NSString *)name color:(UIColor *)color waveRadius:(CGFloat)wave;

#pragma mark Generating Overlay Path

/// Build a given path to conform to the overlay style in the given rect.
- (void)buildOverlayPath:(CGMutablePathRef)path forRect:(CGRect)rect;

/// Build a given path to conform to the overlay style in the given set of rects.
- (void)buildOverlayPath:(CGMutablePathRef)path forRectSet:(ECRectSet *)rects;

@end
