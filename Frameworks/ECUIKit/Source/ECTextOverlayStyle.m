//
//  ECOverlayStyle.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextOverlayStyle.h"
#import <math.h>


@implementation ECTextOverlayStyle

@synthesize name, color, alternativeColor, attributes, pathBlock, shouldStroke, strokeColor, alternativeStrokeColor, shouldFill;

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
        self.shouldFill = YES;
    }
    return self;
}

- (void)buildOverlayPath:(CGMutablePathRef)path 
                 forRect:(CGRect)rect 
             alternative:(BOOL)isAlternative
{
    if (!pathBlock || !path || CGRectIsEmpty(rect))
        return;
    
    pathBlock(path, [ECRectSet rectSetWithRect:rect], isAlternative, attributes);
}

- (void)buildOverlayPath:(CGMutablePathRef)path 
              forRectSet:(ECRectSet *)rect 
             alternative:(BOOL)isAlternative
{
    NSUInteger count = rect.count;
    if (!pathBlock || !path || count == 0)
        return;
    
    pathBlock(path, rect, isAlternative, attributes);
}

#pragma mark -
#pragma mark Class methods

+ (id)highlightTextOverlayStyleWithName:(NSString *)name 
                                  color:(UIColor *)color 
                       alternativeColor:(UIColor *)alternative 
                           cornerRadius:(CGFloat)radius
{
    NSDictionary *attrib = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:radius] forKey:@"cornerRadius"];
    return [[[self alloc] initWithName:name color:color alternativeColor:alternative attributes:attrib pathBlock:^(CGMutablePathRef retPath, ECRectSet *rects, BOOL alt, NSDictionary *attr) {
        [rects enumerateRectsUsingBlock:^(CGRect rect, BOOL *stop) {
            if (radius == 0)
            {
                CGPathAddRect(retPath, NULL, rect);
            }
            else
            {
                CGFloat cradius = [(NSNumber *)[attr objectForKey:@"cornerRadius"] floatValue];
                CGRect innerRect = CGRectInset(rect, cradius, cradius);
                
                CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
                CGFloat outside_right = rect.origin.x + rect.size.width;
                CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
                CGFloat outside_bottom = rect.origin.y + rect.size.height;
                
                CGFloat inside_top = innerRect.origin.y;
                CGFloat outside_top = rect.origin.y;
                CGFloat outside_left = rect.origin.x;
                
                CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
                
                CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
                CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
                CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
                CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
                
                CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
                CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
                CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
                CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
                
                CGPathCloseSubpath(retPath);
            }
        }];
    }] autorelease];
}

+ (id)underlineTextOverlayStyleWithName:(NSString *)name 
                                  color:(UIColor *)color 
                       alternativeColor:(UIColor *)alternative 
                             waveRadius:(CGFloat)wave;
{
    NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithFloat:wave], @"lineWaveRadius", nil];
    ECTextOverlayStyle *result = [[self alloc] initWithName:name color:nil alternativeColor:nil attributes:attrib pathBlock:^(CGMutablePathRef retPath, ECRectSet *rects, BOOL alt, NSDictionary *attr) {
        [rects enumerateRectsUsingBlock:^(CGRect rect, BOOL *stop) {
            CGFloat waveRadius = [[attr objectForKey:@"lineWaveRadius"] floatValue];
            CGFloat liney = rect.origin.y + rect.size.height;
            CGFloat startx = rect.origin.x;
            CGFloat endx = rect.origin.x + rect.size.width;
            CGPathMoveToPoint(retPath, NULL, startx, liney);
            if (!waveRadius)
            {
                CGPathAddLineToPoint(retPath, NULL, endx, liney);
            }
            else while (startx < endx)
            {
                startx += 2 * waveRadius;
                CGPathAddArc(retPath, NULL, startx, liney, waveRadius, M_PI, 0, YES);
                startx += 2 * waveRadius;
                CGPathAddArc(retPath, NULL, startx, liney, waveRadius, M_PI, 0, NO);
            }
        }];
    }];
    result.shouldFill = NO;
    result.shouldStroke = YES;
    result.strokeColor = color;
    result.alternativeStrokeColor = alternative;
    return [result autorelease];
}
@end
