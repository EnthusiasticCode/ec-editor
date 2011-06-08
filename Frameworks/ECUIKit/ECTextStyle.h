//
//  ECTextStyle.h
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

const NSString *ECTSBackgroundColorAttributeName;
const NSString *ECTSFrontCustomOverlayAttributeName;
const NSString *ECTSBackCustomOverlayAttributeName;

typedef enum {
    ECUnderlineStyleNone = 0x00,
    ECUnderlineStyleSingle = 0x01,
    ECUnderlineStyleThick = 0x02,
    ECUnderlineStyleDouble = 0x09,
    ECUnderlinePatternSolid = 0x0000,
    ECUnderlinePatternDot = 0x0100,
    ECUnderlinePatternDash = 0x0200,
    ECUnderlinePatternDashDot = 0x0300,
    ECUnderlinePatternDashDotDot = 0x0400
} ECUnderlineStyle;

typedef void (^ECTextStyleCustomOverlayBlock)(CGContextRef context, CGRect rect);

/// A text style represent attributes to be applied to a string.
@interface ECTextStyle : NSObject

/// The name of the style.
@property (nonatomic, copy) NSString *name;

/// The font to use for this style.
// TODO specify family, attributes instead
@property (nonatomic, strong) UIFont *font;

/// The font color to use for this style.
@property (nonatomic, strong) UIColor *foregroundColor;

/// The font background color for the font.
@property (nonatomic, strong) UIColor *backgroundColor;

// The underline color for the font.
@property (nonatomic, strong) UIColor *underlineColor;

// The style of underline
@property (nonatomic) ECUnderlineStyle underlineStyle;

/// Gets a dictionary of core text compatible attributed string's attributes.
@property (nonatomic, readonly) NSDictionary *CTAttributes;

@property (nonatomic, copy) ECTextStyleCustomOverlayBlock backCustomOverlay;

@property (nonatomic, copy) ECTextStyleCustomOverlayBlock frontCustomOverlay;

/// Initialize a new style with a name.
- (id)initWithName:(NSString *)aName;

/// Create a new style with name and common properties.
+ (id)textStyleWithName:(NSString *)aName font:(UIFont *)aFont color:(UIColor *)aColor;

@end
