//
//  ECMockupButton.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECButton.h"
#import "UIColor+StyleColors.h"
#import <QuartzCore/QuartzCore.h>


@interface ECButton () {
@private
    CGColorRef *backgroundColors;
    CGColorRef *borderColors;
    NSString **titles;
}

@property (nonatomic) CGPathRef buttonPath;

- (void)updateLayerPropertiesForCurrentState;

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

static CGPathRef createButtonShapePath(CGRect rect, CGFloat radius, CGFloat leftArrow, CGFloat rightArrow) 
{
    rect = CGRectInset(rect, 0.5, 0.5);
    
    // No arrows rounded rect result
    if (leftArrow == 0 && rightArrow == 0)
    {
        CGPathRef path = CGPathRetain([UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius].CGPath);
        return path;
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    
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
        CGFloat arrow_size = rightArrow * 0.3;
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
        CGFloat arrow_size = leftArrow * 0.3;
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
    
    return path;
}

#pragma mark -
#pragma mark Properties

@synthesize cornerRadius, leftArrowSize, rightArrowSize;
@synthesize titleLabel, titleInsets;

- (CGPathRef)buttonPath
{
    return [(CAShapeLayer *)self.layer path];
}

- (void)setButtonPath:(CGPathRef)buttonPath
{
    CAShapeLayer *layer = (CAShapeLayer *)self.layer;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.fromValue = (id)layer.path;
    animation.toValue = (id)buttonPath;
    animation.duration = 0.15;
    animation.valueFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [layer addAnimation:animation forKey:nil];
    [layer setPath:buttonPath];
}

- (CGFloat)borderWidth
{
    return [(CAShapeLayer *)self.layer lineWidth];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    [(CAShapeLayer *)self.layer setLineWidth:borderWidth];
}

- (void)setCornerRadius:(CGFloat)radius
{
    if (radius != cornerRadius) 
    {
        cornerRadius = radius;
        CGPathRef path = createButtonShapePath(self.bounds, cornerRadius, leftArrowSize, rightArrowSize);
        self.buttonPath = path;
        CGPathRelease(path);
    }
}

- (void)setLeftArrowSize:(CGFloat)size
{
    if (size != leftArrowSize) 
    {
        leftArrowSize = size;
        CGPathRef path = createButtonShapePath(self.bounds, cornerRadius, leftArrowSize, rightArrowSize);
        self.buttonPath = path;
        CGPathRelease(path);
    }
}

- (void)setRightArrowSize:(CGFloat)size
{
    if (size != rightArrowSize) 
    {
        rightArrowSize = size;
        CGPathRef path = createButtonShapePath(self.bounds, cornerRadius, leftArrowSize, rightArrowSize);
        self.buttonPath = path;
        CGPathRelease(path);
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateLayerPropertiesForCurrentState];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateLayerPropertiesForCurrentState];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self updateLayerPropertiesForCurrentState];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGPathRef path = createButtonShapePath(self.bounds, self->cornerRadius, self->leftArrowSize, self->rightArrowSize);
    self.buttonPath = path;
    CGPathRelease(path);
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    CGPathRef path = createButtonShapePath(self.bounds, self->cornerRadius, self->leftArrowSize, self->rightArrowSize);
    self.buttonPath = path;
    CGPathRelease(path);
}

#pragma mark -
#pragma mark UIControl Methods

static void init(ECButton *self)
{
    CAShapeLayer *layer = (CAShapeLayer *)self.layer;
    
    // Create title layer
    self->titleLabel = [UILabel new];
    self->titleLabel.textAlignment = UITextAlignmentCenter;
    self->titleLabel.adjustsFontSizeToFitWidth = NO;
    self->titleLabel.numberOfLines = 1;
    self->titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    self->titleLabel.font = [UIFont boldSystemFontOfSize:15];
    self->titleLabel.backgroundColor = [UIColor clearColor];
    self->titleLabel.shadowColor = [UIColor styleForegroundShadowColor];
    self->titleLabel.shadowOffset = CGSizeMake(0, 1);
    self->titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Title insets
    self->titleInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    
    // Common properties
    self->cornerRadius = 3;
    self->leftArrowSize = 0;
    self->rightArrowSize = 0;
    self.borderWidth = 1;
    
    // Background colors
    self->backgroundColors = (CGColorRef *)malloc(sizeof(CGColorRef) * 6);
    self->backgroundColors[STATE_NORMAL_IDX] = layer.backgroundColor;
    self->backgroundColors[STATE_HIGHLIGHTED_IDX] = CGColorCreateCopy([UIColor colorWithRed:93.0/255.0 green:94.0/255.0 blue:94.0/255.0 alpha:1.0].CGColor);
    self->backgroundColors[STATE_DISABLED_IDX] = NULL;
    self->backgroundColors[STATE_SELECTED_IDX] = CGColorCreateCopy([UIColor colorWithRed:64.0/255.0 green:92.0/255.0 blue:123.0/255.0 alpha:1.0].CGColor);
    self->backgroundColors[STATE_APPLICATION_IDX] = NULL;
    self->backgroundColors[STATE_RESERVED_IDX] = NULL;
    layer.backgroundColor = NULL;
    
    // Border colors
    self->borderColors = (CGColorRef *)malloc(sizeof(CGColorRef) * 6);
    self->borderColors[STATE_NORMAL_IDX] = CGColorCreateCopy([UIColor colorWithHue:0 saturation:0 brightness:0.01 alpha:1.0].CGColor);
    self->borderColors[STATE_HIGHLIGHTED_IDX] = CGColorCreateCopy(self->borderColors[STATE_NORMAL_IDX]);
    self->borderColors[STATE_DISABLED_IDX] = NULL;
    self->borderColors[STATE_SELECTED_IDX] = CGColorCreateCopy(self->borderColors[STATE_NORMAL_IDX]);
    self->borderColors[STATE_APPLICATION_IDX] = NULL;
    self->borderColors[STATE_RESERVED_IDX] = NULL;
    
    // Titles
    self->titles = (NSString **)malloc(sizeof(NSString *) * 6);
    memset(self->titles, 0, sizeof(NSString *) * 6);
    
    [self updateLayerPropertiesForCurrentState];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    [titleLabel release];
    free(titles);
    free(backgroundColors);
    free(borderColors);
    [super dealloc];
}

+ (Class)layerClass
{
    return [CAShapeLayer class];
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

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
//    CGFloat fontHeight = titleLabel.font.pointSize;
//    titleLabel.frame = CGRectMake(leftArrowSize, (bounds.size.height - fontHeight) / 2.0, (bounds.size.width - leftArrowSize - rightArrowSize - 2 * self.borderWidth), fontHeight);
    titleLabel.frame = UIEdgeInsetsInsetRect(bounds, titleInsets);
}

#pragma mark -
#pragma mark Public methods

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

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    NSUInteger index = stateToIndex(state);
    [titles[index] release];
    titles[index] = [title retain];

    [self updateLayerPropertiesForCurrentState];
}

- (NSString *)titleForState:(UIControlState)state
{
    NSUInteger index = stateToIndex(state);
    return titles[index];
}

#pragma mark -
#pragma mark Private methods

- (void)updateLayerPropertiesForCurrentState
{
    CAShapeLayer *layer = (CAShapeLayer *)self.layer;
    NSUInteger stateIndex = stateToIndex(self.state);
    layer.fillColor = backgroundColors[stateIndex];
    layer.strokeColor = borderColors[stateIndex];
    
    // Title
    if (titles[stateIndex] == nil) 
        stateIndex = STATE_NORMAL_IDX;
    if (titles[stateIndex] == nil) 
    {
        [titleLabel removeFromSuperview];
    }
    else if (![titles[stateIndex] isEqualToString:titleLabel.text])
    {
        titleLabel.text = titles[stateIndex];
//        CGRect bounds = self.bounds;
//        CGFloat fontHeight = titleLabel.font.pointSize;
//        titleLabel.frame = CGRectMake(leftArrowSize, floorf(bounds.size.height - fontHeight) / 2.0, floorf(bounds.size.width - leftArrowSize - rightArrowSize - 2 * self.borderWidth), fontHeight);
        [self addSubview:titleLabel];
    }
}

@end
