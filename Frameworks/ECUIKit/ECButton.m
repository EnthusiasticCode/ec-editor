//
//  ECMockupButton.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECButton.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>


@interface ECButton () {
@private
    CGColorRef *backgroundColors;
    CGColorRef *borderColors;
}

@property (nonatomic) CGMutablePathRef buttonPath;

- (void)updateButtonPath;

@end

@implementation ECButton

#define STATE_NORMAL_IDX      0
#define STATE_HIGHLIGHTED_IDX 1
#define STATE_DISABLED_IDX    2
#define STATE_SELECTED_IDX    3
#define STATE_APPLICATION_IDX 4
#define STATE_RESERVED_IDX    5

static NSUInteger stateToIndex(UIControlState state)
{
    NSUInteger index = STATE_NORMAL_IDX;
    if (state & UIControlStateHighlighted) {
        index = STATE_HIGHLIGHTED_IDX;
    }
    else if (state & UIControlStateSelected) {
        index = STATE_SELECTED_IDX;
    }
    else if (state & UIControlStateDisabled) {
        index = STATE_DISABLED_IDX;
    }
    else if (state & UIControlStateApplication) {
        index = STATE_APPLICATION_IDX;
    }
    else if (state & UIControlStateReserved) {
        index = STATE_RESERVED_IDX;
    }
    return index;
}

static void createButtonShapePath(CGMutablePathRef path, CGRect rect, CGFloat radius, CGFloat leftArrow, CGFloat rightArrow) 
{
    rect = CGRectInset(rect, 0.5, 0.5);
    
    // No arrows rounded rect result
    if (leftArrow == 0 && rightArrow == 0)
    {
        CGPathAddPath(path, NULL, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius].CGPath);
        return;
    }
    
    CGRect innerRect = CGRectInset(rect, radius, radius);
    
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    CGFloat inside_left = innerRect.origin.x + leftArrow;
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width - rightArrow;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    //        CGFloat middle_width = outside_right / 2.0;
    CGFloat middle_height = outside_bottom / 2.0;
    
    // TODO No top arrow for now
    CGPathMoveToPoint(path, NULL, inside_left, outside_top);
    CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
    
    // Right arrow
    if (rightArrow > 0) 
    {
        CGFloat arrow_size = rightArrow * 0.4;
        CGFloat inside_arrow = inside_right + rightArrow + radius * 0.7;
        CGFloat arrow_midtop = middle_height - radius / 2;
        CGFloat arrow_midbottom = arrow_midtop + radius;
        CGPathAddCurveToPoint(path, NULL,
                              inside_right + arrow_size, outside_top, 
                              inside_arrow, arrow_midtop, 
                              inside_arrow, arrow_midtop);
        CGPathAddCurveToPoint(path, NULL,
                              outside_right, middle_height, 
                              outside_right, middle_height, 
                              inside_arrow, arrow_midbottom);
        CGPathAddCurveToPoint(path, NULL,
                              inside_arrow, arrow_midbottom, 
                              inside_right + arrow_size, outside_bottom, 
                              inside_right, outside_bottom);
    }
    else
    {
        CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, radius);
        CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
        CGPathAddArcToPoint(path, NULL, outside_right, outside_bottom, inside_right, outside_bottom, radius);
    }
    
    // TODO no bottom arrow
    CGPathAddLineToPoint(path, NULL, inside_left, outside_bottom);
    
    // Left arrow
    if (leftArrow > 0) 
    {
        CGFloat arrow_size = leftArrow * 0.4;
        CGFloat inside_arrow = inside_left - leftArrow - radius * 0.7;
        CGFloat arrow_midtop = middle_height - radius / 2;
        CGFloat arrow_midbottom = arrow_midtop + radius;
        CGPathAddCurveToPoint(path, NULL,
                              inside_left - arrow_size, outside_bottom,
                              inside_arrow, arrow_midbottom,
                              inside_arrow, arrow_midbottom);
        CGPathAddCurveToPoint(path, NULL,
                              outside_left, middle_height, 
                              outside_left, middle_height, 
                              inside_arrow, arrow_midtop);
        CGPathAddCurveToPoint(path, NULL, 
                              inside_arrow, arrow_midtop, 
                              inside_left - arrow_size, outside_top, 
                              inside_left, outside_top);
    }
    else
    {
        CGPathAddArcToPoint(path, NULL, outside_left, outside_bottom, outside_left, inside_bottom, radius);
        CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
        CGPathAddArcToPoint(path, NULL, outside_left, outside_top, inside_left, outside_top, radius);
    }
    
    CGPathCloseSubpath(path);
}

#pragma mark - Properties

@synthesize cornerRadius, leftArrowSize, rightArrowSize;
@synthesize buttonPath;

- (void)setBorderWidth:(CGFloat)borderWidth
{
    [(CAShapeLayer *)self.layer setLineWidth:borderWidth];
}

- (void)setCornerRadius:(CGFloat)radius
{
    if (radius != cornerRadius) 
    {
        cornerRadius = radius;
        [self updateButtonPath];
    }
}

- (void)setLeftArrowSize:(CGFloat)size
{
    if (size != leftArrowSize) 
    {
        leftArrowSize = size;
        [self updateButtonPath];
    }
}

- (void)setRightArrowSize:(CGFloat)size
{
    if (size != rightArrowSize) 
    {
        rightArrowSize = size;
        [self updateButtonPath];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsDisplay];
}

//- (void)setFrame:(CGRect)frame
//{
//    [super setFrame:frame];
//    
//    CGPathRef path = createButtonShapePath(self.bounds, self->cornerRadius, self->leftArrowSize, self->rightArrowSize);
//    [self setButtonPath:path animated:YES];
//    CGPathRelease(path);
//}
//
//- (void)setBounds:(CGRect)bounds
//{
//    [super setBounds:bounds];
//    
//    CGPathRef path = createButtonShapePath(self.bounds, self->cornerRadius, self->leftArrowSize, self->rightArrowSize);
//    [self setButtonPath:path animated:YES];
//    CGPathRelease(path);
//}

#pragma mark - UIControl Methods

static void preinit(ECButton *self)
{
    // Common properties
    self->cornerRadius = 3;
    self->leftArrowSize = 0;
    self->rightArrowSize = 0;
    self.borderWidth = 1;
    
    // Background colors
    self->backgroundColors = (CGColorRef *)malloc(sizeof(CGColorRef) * 6);
    self->backgroundColors[STATE_NORMAL_IDX] = CGColorCreateCopy([UIColor colorWithWhite:0.9 alpha:1.0].CGColor);
    self->backgroundColors[STATE_HIGHLIGHTED_IDX] = CGColorCreateCopy([UIColor colorWithWhite:0.7 alpha:1.0].CGColor);
    self->backgroundColors[STATE_DISABLED_IDX] = NULL;
    self->backgroundColors[STATE_SELECTED_IDX] = CGColorCreateCopy([UIColor colorWithWhite:0.7 alpha:1.0].CGColor);
    self->backgroundColors[STATE_APPLICATION_IDX] = NULL;
    self->backgroundColors[STATE_RESERVED_IDX] = NULL;
    
    // Border colors
    self->borderColors = (CGColorRef *)malloc(sizeof(CGColorRef) * 6);
    self->borderColors[STATE_NORMAL_IDX] = CGColorCreateCopy([UIColor colorWithWhite:0.16 alpha:1.0].CGColor);
    self->borderColors[STATE_HIGHLIGHTED_IDX] = CGColorCreateCopy(self->borderColors[STATE_NORMAL_IDX]);
    self->borderColors[STATE_DISABLED_IDX] = NULL;
    self->borderColors[STATE_SELECTED_IDX] = CGColorCreateCopy(self->borderColors[STATE_NORMAL_IDX]);
    self->borderColors[STATE_APPLICATION_IDX] = NULL;
    self->borderColors[STATE_RESERVED_IDX] = NULL;
}

static void init(ECButton *self)
{
    self.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    [self updateButtonPath];
}

- (id)initWithFrame:(CGRect)frame
{
    preinit(self);
    if ((self = [super initWithFrame:frame]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    preinit(self);
    if ((self = [super initWithCoder:aDecoder]))
    {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    if (buttonPath)
        CGPathRelease(buttonPath);
    free(backgroundColors);
    free(borderColors);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.hidden)
        return nil;
    
    CGPathRef path = self.buttonPath;
    if (path) 
    {
        if (CGPathContainsPoint(path, NULL, point, NO))
            return self;
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSUInteger stateIndex = stateToIndex(self.state);
    CGContextSetFillColorWithColor(context, backgroundColors[stateIndex]);
    CGContextSetStrokeColorWithColor(context, borderColors[stateIndex]);
    
    CGContextAddPath(context, buttonPath);
    CGContextFillPath(context);
    
    CGContextAddPath(context, buttonPath);
    CGContextStrokePath(context);
}

#pragma mark - Public methods

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    NSUInteger index = stateToIndex(state);
    if (backgroundColors[index])
        CGColorRelease(backgroundColors[index]);
    backgroundColors[index] = color ? CGColorCreateCopy(color.CGColor) : NULL;
    
    if (self.state == state)
        [(CAShapeLayer *)self.layer setFillColor:backgroundColors[index]];
}

- (UIColor *)backgroundColorForState:(UIControlState)state
{
    NSUInteger index = stateToIndex(state);
    return backgroundColors[index] ? [UIColor colorWithCGColor:backgroundColors[index]] : nil;
}

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state
{
    NSUInteger index = stateToIndex(state);
    if (borderColors[index])
        CGColorRelease(borderColors[index]);
    borderColors[index] = color ? CGColorCreateCopy(color.CGColor) : NULL;
    
    if (self.state == state)
        [(CAShapeLayer *)self.layer setStrokeColor:borderColors[index]];
}

- (UIColor *)borderColorForState:(UIControlState)state
{
    NSUInteger index = stateToIndex(state);
    return borderColors[index] ? [UIColor colorWithCGColor:borderColors[index]] : nil;
}

#pragma mark - Private methods

- (void)updateButtonPath
{
    if (buttonPath)
        CGPathRelease(buttonPath);
    
    buttonPath = CGPathCreateMutable();
    createButtonShapePath(buttonPath, self.bounds, cornerRadius, leftArrowSize, rightArrowSize);
}

@end
