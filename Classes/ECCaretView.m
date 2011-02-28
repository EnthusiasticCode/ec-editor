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

@synthesize caretColor;
@synthesize caretShapeBlock;
@synthesize caretShape = _caretShape;
@synthesize pulsePerSecond;
@synthesize blink;

- (void)setBlink:(BOOL)shouldBlink
{
    if (blink != shouldBlink)
    {
        blink = shouldBlink;
        if (shouldBlink)
        {
            [UIView animateWithDuration:1.0 / (pulsePerSecond * 2) delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone | UIViewAnimationOptionAllowUserInteraction animations:^(void) {
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

#pragma mark UIView override

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = nil;
        self.caretColor = [UIColor redColor];
        self.clearsContextBeforeDrawing = YES;
        self.pulsePerSecond = 2;
        self.userInteractionEnabled = NO;
        self.caretShapeBlock = ^(CGRect b) {
            CGMutablePathRef p = CGPathCreateMutable();
            CGPathAddRect(p, NULL, b);
            return (CGPathRef)p;
        };
        _caretShape = caretShapeBlock(self.bounds);
    }
    return self;
}

- (void)dealloc
{
    if (_caretShape)
        CGPathRelease(_caretShape);
    [caretShapeBlock release];
    self.caretColor = nil;
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    [self drawInContext:UIGraphicsGetCurrentContext()];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (caretShapeBlock)
    {
        if (_caretShape)
            CGPathRelease(_caretShape);
        _caretShape = caretShapeBlock(self.bounds);
    }
}

#pragma mark Custom methods

- (void)drawInContext:(CGContextRef)context
{
    [self.caretColor setFill];
    CGContextAddPath(context, _caretShape);
    CGContextFillPath(context);
}

@end
