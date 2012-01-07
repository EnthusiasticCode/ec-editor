//
//  ECTextStyle.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextStyle.h"
#import <CoreText/CoreText.h>


NSString *const ECTSBackgroundColorAttributeName = @"BackgroundColor";
NSString *const ECTSFrontCustomOverlayAttributeName = @"ECTextStyleFrontCustomOverlayAttribute";
NSString *const ECTSBackCustomOverlayAttributeName = @"ECTextStyleBackCustomOverlayAttribute";


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
    [self setFont:aFont bold:NO italic:NO];
}

- (void)setFont:(UIFont *)aFont bold:(BOOL)isBold italic:(BOOL)isItalic
{
    font = aFont;
    
    if (font)
    {
        CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
            font.fontName, kCTFontNameAttribute, 
            [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithFloat:isBold ? 0.5 : 0], kCTFontWeightTrait, 
                 [NSNumber numberWithFloat:isItalic ? 1.0 : 0], kCTFontSlantTrait, 
            nil], kCTFontTraitsAttribute, nil]);
        CTFontRef CTFont = CTFontCreateWithFontDescriptor(fontDescriptor, font.pointSize, NULL);
        [CTAttributes setObject:(__bridge id)CTFont forKey:(__bridge id)kCTFontAttributeName];
        CFRelease(CTFont);
        CFRelease(fontDescriptor);
    }
    else
    {
        [CTAttributes removeObjectForKey:(__bridge id)kCTFontAttributeName];
    }
}

- (void)setForegroundColor:(UIColor *)aForegroundColor
{
    foregroundColor = aForegroundColor;
    
    if (foregroundColor)
    {
        [CTAttributes setObject:(__bridge id)foregroundColor.CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:(__bridge id)kCTForegroundColorAttributeName];
    }
}

- (void)setBackgroundColor:(UIColor *)aBackgroundColor
{
    backgroundColor = aBackgroundColor;
    
    if (backgroundColor) 
    {
        [CTAttributes setObject:(__bridge id)backgroundColor.CGColor forKey:ECTSBackgroundColorAttributeName];
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
        [CTAttributes setObject:(__bridge id)underlineColor.CGColor forKey:(__bridge id)kCTUnderlineColorAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:(__bridge id)kCTUnderlineColorAttributeName];
    }
}

- (void)setUnderlineStyle:(ECUnderlineStyle)aUnderlineStyle
{
    underlineStyle = aUnderlineStyle;
    
    if (underlineStyle & 0xFF) 
    {
        [CTAttributes setObject:[NSNumber numberWithInt:underlineStyle] forKey:(__bridge id)kCTUnderlineStyleAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:(__bridge id)kCTUnderlineStyleAttributeName];
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
