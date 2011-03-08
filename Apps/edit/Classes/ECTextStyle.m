//
//  ECTextStyle.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextStyle.h"
#import <CoreText/CoreText.h>

@implementation ECTextStyle

#pragma mark Properties

@synthesize name;
@synthesize font;
@synthesize foregroundColor;
@synthesize CTAttributes;

- (void)setFont:(UIFont *)aFont
{
    [font release];
    font = [aFont retain];
    
    if (font)
    {
        // TODO check for leak?
        CTFontRef CTFont = CTFontCreateWithName((CFStringRef)font.familyName, font.pointSize, &CGAffineTransformIdentity);
        [CTAttributes setObject:(id)CTFont forKey:(id)kCTFontAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:(id)kCTFontAttributeName];
    }
}

- (void)setForegroundColor:(UIColor *)aForegroundColor
{
    [foregroundColor release];
    foregroundColor = [aForegroundColor retain];
    
    if (foregroundColor)
    {
        [CTAttributes setObject:(id)foregroundColor.CGColor forKey:(id)kCTForegroundColorAttributeName];
    }
    else
    {
        [CTAttributes removeObjectForKey:(id)kCTForegroundColorAttributeName];
    }
}

#pragma mark Public methods

- (id)init
{
    if ((self = [super init]))
    {
        CTAttributes = [[NSMutableDictionary alloc] init];
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

- (void)dealloc
{
    [name release];
    [font release];
    [foregroundColor release];
    [CTAttributes release];
    [super dealloc];
}

#pragma mark Class methods

+ (id)textStyleWithName:(NSString *)aName font:(UIFont *)aFont color:(UIColor *)aColor
{
    ECTextStyle *style = (ECTextStyle *)[[self alloc] initWithName:aName];
    style.font = aFont;
    style.foregroundColor = aColor;
    return [style autorelease];
}

@end
