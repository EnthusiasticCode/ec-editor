//
//  ECCaretView.m
//  edit
//
//  Created by Nicola Peduzzi on 26/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCaretView.h"


@implementation ECCaretView

#pragma mark Properties

@synthesize pulsePerSecond;

@synthesize blink;

- (void)setBlink:(BOOL)shouldBlink
{
    if (blink != shouldBlink)
    {
        blink = shouldBlink;
        if (shouldBlink)
        {
            [UIView animateWithDuration:1.0 / (pulsePerSecond * 2) delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone animations:^(void) {
                self.alpha = 0.0;
            } completion:nil];
        }
        else
        {
            [UIView animateWithDuration:1.0 / (pulsePerSecond * 2) animations:^(void) {
                [UIView setAnimationBeginsFromCurrentState:YES];
                self.alpha = 1.0;
            }];
        }
    }
}

@synthesize caretShape;

- (void)setCaretShape:(CGPathRef)aCaretShape
{
    if (aCaretShape)
    {
        if (caretShape)
            CGPathRelease(caretShape);
        
        caretShape = CGPathRetain(aCaretShape);
    }
}

#pragma mark UIView override

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [UIColor redColor];
        self.clearsContextBeforeDrawing = YES;
        self.pulsePerSecond = 2;
        // Create default caret shape
        CGMutablePathRef p = CGPathCreateMutable();
        // TODO rounded rect
        CGPathAddRect(p, NULL, (CGRect){ {0, 0}, frame.size });
        self.caretShape = p;
    }
    return self;
}

- (void)dealloc
{
    if (caretShape)
        CGPathRelease(caretShape);
    
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    [self drawInContext:UIGraphicsGetCurrentContext()];
}

#pragma mark Custom methods

- (void)drawInContext:(CGContextRef)context
{
    [self.backgroundColor setFill];
    CGContextAddPath(context, caretShape);
    CGContextFillPath(context);
}

@end
