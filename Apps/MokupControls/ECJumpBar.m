//
//  ECJumpBarView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECJumpBar.h"
#import "ECMockupButton.h"
#import <QuartzCore/QuartzCore.h>

#define BUTTON_ARROW_WIDTH 10
#define TEXT_PADDING 8

@interface ECJumpBar () {
@private
    NSMutableArray *buttonStack;
    UITextField *searchField;
    
    BOOL delegateHasTapAtStackIndex;
    BOOL delegateHasDidPopButtonAtStackIndex;
    BOOL delegateHasChangedSearchStringTo;
}
@end

@implementation ECJumpBar

#pragma mark -
#pragma mark Properties

@synthesize delegate;
@synthesize cornerRadius;
@synthesize minimumSearchFieldWidth;
@synthesize minimumStackButtonWidth;
@synthesize maximumStackButtonWidth;
@synthesize maximumButtonStackSize;
@synthesize font;
@synthesize textColor;
@synthesize textShadowColor;
@synthesize textShadowOffset;
@synthesize buttonColor;
@synthesize buttonHighlightColor;
@synthesize borderColor;
@synthesize borderWidth;

- (void)setDelegate:(id<ECJumpBarDelegate>)aDelegate
{
    delegate = aDelegate;
    delegateHasTapAtStackIndex = [delegate respondsToSelector:@selector(jumpBarView:tapAtStackIndex:)];
    delegateHasDidPopButtonAtStackIndex = [delegate respondsToSelector:@selector(jumpBarView:didPopButtonAtStackIndex:)];
    delegateHasChangedSearchStringTo = [delegate respondsToSelector:@selector(jumpBarView:changedSearchStringTo:)];
}

- (void)setCornerRadius:(CGFloat)radius
{
    cornerRadius = radius;
    self.layer.cornerRadius = radius;
    // TODO set buttons radius
}

- (void)setMinimumStackButtonWidth:(CGFloat)value
{
    minimumStackButtonWidth = value;
    [self setNeedsLayout];
}

- (void)setMaximumStackButtonWidth:(CGFloat)value
{
    maximumStackButtonWidth = value;
    [self setNeedsLayout];
}

- (NSUInteger)stackSize
{
    return [buttonStack count];
}

- (void)setFont:(UIFont *)aFont
{
    [font release];
    font = [aFont retain];
    searchField.font = font;
    for (ECMockupButton *button in buttonStack)
        button.titleLabel.font = font;
}

- (void)setTextColor:(UIColor *)aColor
{
    [textColor release];
    textColor = [aColor retain];
    searchField.textColor = textColor;
    for (ECMockupButton *button in buttonStack)
        [button setTitleColor:textColor forState:UIControlStateNormal];
}

- (void)setTextShadowColor:(UIColor *)aColor
{
    [textShadowColor release];
    textShadowColor = [aColor retain];
    if (textShadowColor) 
    {
        searchField.layer.shadowColor = textShadowColor.CGColor;
        searchField.layer.shadowOpacity = 1;
        searchField.layer.shadowRadius = 0;
    }
    else
    {
        searchField.layer.shadowColor = NULL;
        searchField.layer.shadowOpacity = 0;
    }
    for (ECMockupButton *button in buttonStack)
        [button setTitleShadowColor:textShadowColor forState:UIControlStateNormal];
}

- (void)setTextShadowOffset:(CGSize)anOffset
{
    textShadowOffset = anOffset;
    searchField.layer.shadowOffset = textShadowOffset;
    for (ECMockupButton *button in buttonStack)
        button.titleLabel.shadowOffset = textShadowOffset;
}

- (void)setBorderColor:(UIColor *)aColor
{
    [borderColor release];
    borderColor = [aColor retain];
    self.layer.borderColor = borderColor.CGColor;
    for (ECMockupButton *button in buttonStack)
        button.borderColor = borderColor;
}

- (void)setBorderWidth:(CGFloat)width
{
    borderWidth = width;
    self.layer.borderWidth = width;
//    for (ECMockupButton *button in buttonStack)
//        button.borderWidth = borderWidth
}

- (void)setSearchString:(NSString *)aString
{
    searchField.text = aString;
    if (delegateHasChangedSearchStringTo)
        [delegate jumpBarView:self changedSearchStringTo:aString];
}

- (NSString *)searchString
{
    return searchField.text;
}

#pragma mark -
#pragma mark UIView Methods

static void init(ECJumpBar *self)
{
    self->searchField = [[UITextField alloc] initWithFrame:CGRectZero];
    self->searchField.backgroundColor = nil;
    self->searchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self->searchField.borderStyle = UITextBorderStyleNone;
    self->searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.minimumSearchFieldWidth = 0.2;
    [self addSubview:self->searchField];
    [self->searchField release];
    self->searchField.text = @"Search";
    //
    self.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    self.textColor = [UIColor colorWithHue:0 saturation:0 brightness:0.01 alpha:1];
    self.textShadowColor = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3];
    self.textShadowOffset = CGSizeMake(0, 1);
    self.buttonColor = [UIColor colorWithHue:0 saturation:0 brightness:0.23 alpha:1];
    self.buttonHighlightColor = [UIColor colorWithRed:93.0/255.0 green:94.0/255.0 blue:94.0/255.0 alpha:1.0];
    self.cornerRadius = 3;
    self.borderColor = self.textColor;
    self.borderWidth = 1;
    self->minimumStackButtonWidth = 60;
    self->maximumStackButtonWidth = 160;
    self->maximumButtonStackSize = 9;
    //
    self.layer.masksToBounds = YES;
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
    // TODO think better
    [super initWithCoder:aDecoder];
    init(self);
    return self;
}

- (void)dealloc
{
    self.font = nil;
    self.textColor = nil;
    self.textShadowColor = nil;
    self.buttonColor = nil;
    self.buttonHighlightColor = nil;
    self.borderColor = nil;
    [buttonStack release];
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    CGPoint origin = bounds.origin;
    CGSize size = bounds.size;
    
    // Calculate maximum usable width for buttons
    CGFloat maxTotWidth = size.width;
    if (minimumSearchFieldWidth < 1.0)
        maxTotWidth *= (1.0 - minimumSearchFieldWidth);
    else
        maxTotWidth -= minimumSearchFieldWidth;
    
    // Calculte button size
    CGSize buttonSize = size;
    buttonSize.width = maxTotWidth / [buttonStack count];
    if (buttonSize.width < minimumStackButtonWidth)
        buttonSize.width = minimumStackButtonWidth;
    else if (buttonSize.width > maximumStackButtonWidth)
        buttonSize.width = maximumStackButtonWidth;
    buttonSize.width = ceilf(buttonSize.width);
    
    // Layout buttons
    for (UIControl *button in buttonStack) 
    {
        button.frame = (CGRect){ origin, buttonSize };
        origin.x += buttonSize.width - BUTTON_ARROW_WIDTH - TEXT_PADDING;
        size.width -= buttonSize.width;
    }
    
    // Layout search field
    if ([buttonStack count])
        origin.x += BUTTON_ARROW_WIDTH + TEXT_PADDING;
    origin.x += TEXT_PADDING;
    size.width = bounds.size.width - origin.x - TEXT_PADDING;
    searchField.frame = (CGRect){ origin, size };
}

#pragma mark -
#pragma mark Public Methods

- (UIButton *)buttonAtStackIndex:(NSUInteger)index
{
    if (index >= [buttonStack count])
        return nil;
    return [buttonStack objectAtIndex:index];
}

- (NSUInteger)pushButtonWithTitle:(NSString *)title
{    
    // Generate new button
    ECMockupButton *button = [ECMockupButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = self.font;
    button.titleLabel.shadowOffset = self.textShadowOffset;
    button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    button.titleEdgeInsets = UIEdgeInsetsMake(0, TEXT_PADDING, 0, BUTTON_ARROW_WIDTH + TEXT_PADDING);
    [button setTitleShadowColor:self.textShadowColor forState:UIControlStateNormal];
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
    [button setBackgroundColor:self.buttonColor forState:UIControlStateNormal];
    [button setBackgroundColor:self.buttonHighlightColor forState:UIControlStateHighlighted];
    button.arrowSizes = UIEdgeInsetsMake(0, 0, 0, BUTTON_ARROW_WIDTH);
    
    // Add button to view
    if ([buttonStack count])
        [self insertSubview:button belowSubview:[buttonStack lastObject]];
    else
        [self insertSubview:button aboveSubview:searchField];
    
    // Add button to stack
    if (!buttonStack)
        buttonStack = [[NSMutableArray alloc] initWithCapacity:maximumButtonStackSize];
    [buttonStack addObject:button];
    
    [self setNeedsLayout];
    
    return [buttonStack count] - 1;
}

- (void)popButton
{
    UIControl *button = (UIControl *)[buttonStack lastObject];
    if (button) 
    {
        button.hidden = YES;
        [button removeFromSuperview];
        if (delegateHasDidPopButtonAtStackIndex) 
        {
            NSUInteger index = [buttonStack indexOfObject:button];
            [buttonStack removeObjectAtIndex:index];
            [delegate jumpBarView:self didPopButtonAtStackIndex:index];
        }
        else 
        {
            [buttonStack removeObject:button];
        }
    }
}

- (void)popButtonsDownThruIndex:(NSUInteger)index
{
    NSUInteger count = [buttonStack count];
    if (count && count > index) 
    {
        count -= index;
        while (count--)
            [self popButton];
    }
}

@end
