//
//  ECInverseCornerShapeView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECInverseCornerShapeView.h"
#import <QuartzCore/QuartzCore.h>

static CGPathRef createRoundedPathWithSize(CGSize size)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, size.width);
    CGPathAddLineToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, size.height, 0);
    CGPathAddArcToPoint(path, NULL, 0, 0, 0, size.width, size.height);
    return path;
}


@implementation ECInverseCornerShapeView

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [super setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (UIColor *)backgroundColor
{
    return [UIColor colorWithCGColor:[(CAShapeLayer *)self.layer fillColor]];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [(CAShapeLayer *)self.layer setFillColor:backgroundColor.CGColor];
}

- (void)setBounds:(CGRect)bounds
{
    if (CGRectEqualToRect(bounds, self.bounds))
        return;
    
    [super setBounds:bounds];
    
    // Create top left inverse corner shape
    CGPathRef path = createRoundedPathWithSize(bounds.size);
    [(CAShapeLayer *)self.layer setPath:path];
    CGPathRelease(path);
}

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    [super setFrame:frame];
    
    // Create top left inverse corner shape
    CGPathRef path = createRoundedPathWithSize(frame.size);
    [(CAShapeLayer *)self.layer setPath:path];
    CGPathRelease(path);
}

@end
