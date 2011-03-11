//
//  ECSelectionHandleView.m
//  edit
//
//  Created by Nicola Peduzzi on 04/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECSelectionHandleView.h"

@interface ECSelectionHandleView ()

- (void)handleDragging:(UIPanGestureRecognizer *)recognizer;

@end

@implementation ECSelectionHandleView

@synthesize delegate, side;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        self.opaque = NO;
        
        dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragging:)];
        [self addGestureRecognizer:dragRecognizer];
    }
    return self;
}


- (void)dealloc
{
    [dragRecognizer release];
    [super dealloc];
}


- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
//    for (UIGestureRecognizer *r in self.gestureRecognizers) {
//        r.enabled = !hidden;
//    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.backgroundColor setFill];
    CGContextFillEllipseInRect(context, self.bounds);
}


- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(8, 8);
}

#pragma mark -
#pragma mark ECSelectionHandleView methods

- (void)applyToRect:(CGRect)rect
{
    CGRect frame = self.frame;
    
    if (side & ECSelectionHandleSideLeft)
        rect.origin.x -= round(frame.size.width / 2);
    else if (side & ECSelectionHandleSideRight)
        rect.origin.x += rect.size.width - round(frame.size.width / 2);
    else
        rect.origin.x += round((rect.size.width - frame.size.width) / 2);
    
    if (side & ECSelectionHandleSideTop)
        rect.origin.y -= round(frame.size.height / 2);
    else if (side & ECSelectionHandleSideBottom)
        rect.origin.y += rect.size.height - round(frame.size.height / 2);
    else
        rect.origin.y += round((rect.size.height - frame.size.height) / 2);
    
    frame.origin = rect.origin;
    self.frame = frame;
}

#pragma mark -
#pragma mark Private methods

- (void)handleDragging:(UIPanGestureRecognizer *)recognizer
{
//    if (delegate && [delegate respondsToSelector:@selector(selectionHandle:draggedTo:andStop:)])
//    {
//        UIGestureRecognizerState state = recognizer.state;
//        
//        if (state == UIGestureRecognizerStateBegan)
//        {
//            dragStartPoint = self.center;
//        }
//        
//        CGPoint delta = [recognizer translationInView:self];
//        
//        [delegate selectionHandle:self draggedTo:(CGPoint){ dragStartPoint.x + delta.x, dragStartPoint.y + delta.y  } andStop:(state == UIGestureRecognizerStateCancelled || state == UIGestureRecognizerStateEnded)];
//    }
}

@end
