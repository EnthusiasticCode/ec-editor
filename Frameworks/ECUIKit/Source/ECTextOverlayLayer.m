//
//  ECTextOverlayLayer.m
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextOverlayLayer.h"


@implementation ECTextOverlayLayer

#pragma mark Properties

@synthesize overlayStyle;
@synthesize overlayRectSets;

- (void)setOverlayRectSets:(NSArray *)aRectSet
{
    [overlayRectSets release];
    overlayRectSets = [aRectSet retain];
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Public methods

- (id)initWithTextOverlayStyle:(ECTextOverlayStyle *)aStyle
{
    if ((self = [super init]))
    {
        self.overlayStyle = aStyle;
    }
    return self;
}

#pragma mark -
#pragma mark CALayer methods

- (void)dealloc
{
    [overlayStyle release];
    [overlayRectSets release];
    [super dealloc];
}

- (BOOL)isGeometryFlipped
{
    return YES;
}

- (id<CAAction>)actionForKey:(NSString *)event
{
    // TODO return style one.
    return [super actionForKey:event];
}

- (void)drawInContext:(CGContextRef)context
{
    if (overlayStyle && overlayRectSets)
    {
        // TODO move drawing in style?
        CGMutablePathRef path;
        for (ECRectSet *rects in overlayRectSets) {
            // Get overlay path
            path = CGPathCreateMutable();
            [overlayStyle buildOverlayPath:path forRectSet:rects];
            // Fill
            if (overlayStyle.color)
            {
                CGContextAddPath(context, path);
                CGContextSetFillColorWithColor(context, overlayStyle.color.CGColor);
                CGContextFillPath(context);
            }
            // Stroke
            if (overlayStyle.strokeColor)
            {
                CGContextAddPath(context, path);
                CGContextSetStrokeColorWithColor(context, overlayStyle.strokeColor.CGColor);
                CGContextStrokePath(context);
            }
            CGPathRelease(path);
        }
    }
}

@end
