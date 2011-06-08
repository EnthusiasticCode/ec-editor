//
//  ECTextStyle.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextStyle.h"
#import <CoreText/CoreText.h>


const NSString *ECTSBackgroundColorAttributeName = @"ECTextStyleBackgroundAttribute";
const NSString *ECTSFrontCustomOverlayAttributeName = @"ECTextStyleFrontCustomOverlayAttribute";
const NSString *ECTSBackCustomOverlayAttributeName = @"ECTextStyleBackCustomOverlayAttribute";


@interface ECTextStyle () {
@private
    NSMutableDictionary *CTAttributes;
}
@end

@implementation ECTextStyle

#pragma mark Properties

@synthesize name, font, foregroundColor, backgroundColor, underlineColor, underlineStyle, backCustomOverlay, frontCustomOverlay, CTAttributes;

- (void)setFont:(UIFont *)aFont
{
    font = aFont;
    
    if (font)
    {
        CTFontRef CTFont = CTFontCreateWithName((CFStringRef)objc_unretainedPointer(font.fontName), font.pointSize, NULL);
        [CTAttributes setObject:objc_unretainedObject(CTFont) forKey:objc_unretainedObject(kCTFontAttributeName)];
        CFRelease(CTFont);
    }
    else
    {
        [CTAttributes removeObjectForKey:(id)kCTFontAttributeName];
    }
}

- (void)setForegroundColor:(UIColor *)aForegroundColor
{
    foregroundColor = aForegroundColor;
    
    if (foregroundColor)
    {
        [CTAttributes setObject:objc_unretainedObject(foregroundColor.CGColor) forKey:objc_unretainedObject(kCTForegroundColorAttributeName)];
    }
    else
    {
        [CTAttributes removeObjectForKey:(id)kCTForegroundColorAttributeName];
    }
}

- (void)setBackgroundColor:(UIColor *)aBackgroundColor
{
    backgroundColor = aBackgroundColor;
    
    if (backgroundColor) 
    {
        [CTAttributes setObject:objc_unretainedObject(backgroundColor.CGColor) forKey:ECTSBackgroundColorAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:ECTSBackgroundColorAttributeName];
    }
}

- (void)setUnderlineColor:(UIColor *)aUnderlineColor
{
    underlineColor = aUnderlineColor;
    
    if (underlineColor) 
    {
        [CTAttributes setObject:objc_unretainedObject(underlineColor.CGColor) forKey:objc_unretainedObject(kCTUnderlineColorAttributeName)];
    }
    else
    {
        [CTAttributes removeObjectForKey:(id)kCTUnderlineColorAttributeName];
    }
}

- (void)setUnderlineStyle:(ECUnderlineStyle)aUnderlineStyle
{
    underlineStyle = aUnderlineStyle;
    
    if (underlineStyle & 0xFF) 
    {
        [CTAttributes setObject:[NSNumber numberWithInt:underlineStyle] forKey:(id)kCTUnderlineStyleAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:(id)kCTUnderlineStyleAttributeName];
    }
}

- (void)setFrontCustomOverlay:(ECTextStyleCustomOverlayBlock)block
{
    frontCustomOverlay = [block copy];
    
    if (frontCustomOverlay) 
    {
        [CTAttributes setObject:frontCustomOverlay forKey:ECTSFrontCustomOverlayAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:ECTSFrontCustomOverlayAttributeName];
    }
}

- (void)setBackCustomOverlay:(ECTextStyleCustomOverlayBlock)block
{
    backCustomOverlay = [block copy];
    
    if (backCustomOverlay) 
    {
        [CTAttributes setObject:backCustomOverlay forKey:ECTSBackCustomOverlayAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:ECTSBackCustomOverlayAttributeName];
    }
}


#pragma mark Public methods

- (id)init
{
    if ((self = [super init]))
    {
        CTAttributes = [[NSMutableDictionary alloc] init];
        // Adding default ligature attribute
        [CTAttributes setObject:[NSNumber numberWithInt:0] forKey:(id)kCTLigatureAttributeName];
    }
    return self;
}

- (id)initWithName:(NSString *)aName
{
    if ((self = [self init]))
    {
        self.name = aName;
    }
    return self;
}


#pragma mark Class methods

+ (id)textStyleWithName:(NSString *)aName font:(UIFont *)aFont color:(UIColor *)aColor
{
    ECTextStyle *style = (ECTextStyle *)[[self alloc] initWithName:aName];
    style.font = aFont;
    style.foregroundColor = aColor;
    return style;
}

@end
