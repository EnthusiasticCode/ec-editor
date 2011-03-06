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

#pragma mark -
#pragma mark Public methods

- (id)initWithOverlayStyle:(ECTextOverlayStyle *)aStyle
{
    if ((self = [super init]))
    {
        self.overlayStyle = aStyle;
    }
    return self;
}

- (void)setTextOverlays:(NSArray *)rects animate:(BOOL)doAnimation
{
    if (doAnimation)
        self.opacity = 0;
    [overlayRects release];
    overlayRects = [rects retain];
    [self setNeedsDisplay];
    if (doAnimation)
        self.opacity = 1;
}

#pragma mark -
#pragma mark CALayer methods

- (void)dealloc
{
    [overlayRects release];
    [super dealloc];
}

- (BOOL)isGeometryFlipped
{
    return YES;
}

- (void)drawInContext:(CGContextRef)context
{
    if (overlayStyle)
    {
        CGMutablePathRef path;
        for (ECTextOverlay *overlay in overlayRects) {
            // Get overlay path
            path = CGPathCreateMutable();
            if (overlay.rectSet)
            {
                [overlayStyle buildOverlayPath:path forRectSet:overlay.rectSet alternative:overlay.isAlternative];
            }
            else
            {
                [overlayStyle buildOverlayPath:path forRect:overlay.rect alternative:overlay.isAlternative];
            }
            // Fill
            if (overlayStyle.shouldFill)
            {
                CGContextAddPath(context, path);
                CGContextSetFillColorWithColor(context, overlay.isAlternative ? overlayStyle.alternativeColor.CGColor : overlayStyle.color.CGColor);
                CGContextFillPath(context);
            }
            // Stroke
            if (overlayStyle.shouldStroke)
            {
                CGContextAddPath(context, path);
                CGContextSetStrokeColorWithColor(context, overlay.isAlternative ? overlayStyle.alternativeStrokeColor.CGColor : overlayStyle.strokeColor.CGColor);
                CGContextStrokePath(context);
            }
            CGPathRelease(path);
        }
    }
}

@end
