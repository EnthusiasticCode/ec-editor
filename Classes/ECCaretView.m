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

@synthesize blink;

- (void)setBlink:(BOOL)shouldBlink
{
    if (blink != shouldBlink)
    {
        blink = shouldBlink;
        // TODO set blinking animation
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
        // Create default caret shape
        //CGMutablePathRef p = CGPathCreateMutable();
        // TODO
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
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawInContext:context];
}

#pragma mark Custom methods

- (void)drawInContext:(CGContextRef)context
{
    [self.backgroundColor setFill];
}

@end
