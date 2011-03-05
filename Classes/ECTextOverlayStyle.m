//
//  ECOverlayStyle.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextOverlayStyle.h"


@implementation ECTextOverlayStyle

@synthesize name, color, alternativeColor, attributes, pathBlock;

- (id)initWithName:(NSString *)aName 
             color:(UIColor *)aColor 
  alternativeColor:(UIColor *)anAlternative 
        attributes:(NSDictionary *)anyAttrib 
         pathBlock:(BuildOverlayPathForRectBlock)aBlock
{
    if ((self = [super init]))
    {
        self.name = aName;
        self.color = aColor;
        self.alternativeColor = anAlternative;
        self.attributes = anyAttrib;
        self.pathBlock = aBlock;
    }
    return self;
}

- (void)buildOverlayPath:(CGMutablePathRef)path 
                 forRect:(CGRect)rect 
             alternative:(BOOL)isAlternative
{
    if (!pathBlock || !path || CGRectIsEmpty(rect))
        return;
    
    pathBlock(path, rect, isAlternative ? alternativeColor : color, attributes);
}

#pragma mark -
#pragma mark Class methods

+ (id)highlightTextOverlayStyleWithName:(NSString *)name 
                                  color:(UIColor *)color 
                       alternativeColor:(UIColor *)alternative 
                           cornerRadius:(CGFloat)radius
{
    return [[[self alloc] initWithName:name color:color alternativeColor:alternative attributes:nil pathBlock:^(CGMutablePathRef result, CGRect rect, UIColor *color, NSDictionary *attr) {
        CGPathAddRect(result, NULL, rect);
    }] autorelease];
}

+ (id)underlineTextOverlayStyleWithName:(NSString *)name 
                                  color:(UIColor *)color 
                       alternativeColor:(UIColor *)alternative 
                              thickness:(CGFloat)thickness 
                                  shape:(NSString *)shape
{
    
}
@end
