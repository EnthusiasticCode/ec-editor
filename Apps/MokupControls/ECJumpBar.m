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

@interface ECJumpBar () {
@private
    UITextField *searchField;
    
    UIControl *collapsedButton;
    NSRange collapsedRange;
    
    BOOL delegateHasDidPushControlAtStackIndex;
    BOOL delegateHasDidPopControlAtStackIndex;
    BOOL delegateHasDidCollapseToControlCollapsedRange;
    BOOL delegateHasChangedSearchStringTo;
}

- (void)searchFieldAction:(id)sender;

@end

@implementation ECJumpBar

#pragma mark -
#pragma mark Properties

@synthesize delegate;
@synthesize cornerRadius;
@synthesize minimumSearchFieldWidth;
@synthesize minimumStackButtonWidth;
@synthesize maximumStackButtonWidth;
@synthesize font;
@synthesize textColor;
@synthesize textShadowColor;
@synthesize textShadowOffset;
@synthesize buttonColor;
@synthesize buttonHighlightColor;
@synthesize borderColor;
@synthesize borderWidth;
@synthesize textInsets;
//@synthesize controlMargin;

- (void)setDelegate:(id<ECJumpBarDelegate>)aDelegate
{
    delegate = aDelegate;
    delegateHasDidPushControlAtStackIndex = [delegate respondsToSelector:@selector(jumpBar:didPushControl:atStackIndex:)];
    delegateHasDidPopControlAtStackIndex = [delegate respondsToSelector:@selector(jumpBar:didPopControl:atStackIndex:)];
    delegateHasDidCollapseToControlCollapsedRange = [delegate respondsToSelector:@selector(jumpBar:didCollapseToControl:collapsedRange:)];
    delegateHasChangedSearchStringTo = [delegate respondsToSelector:@selector(jumpBar:changedSearchStringTo:)];
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
    return [controlsStack count];
}

- (void)setFont:(UIFont *)aFont
{
    [font release];
    font = [aFont retain];
    searchField.font = font;
    for (ECMockupButton *button in controlsStack)
        button.titleLabel.font = font;
}

- (void)setTextColor:(UIColor *)aColor
{
    [textColor release];
    textColor = [aColor retain];
    searchField.textColor = textColor;
    for (ECMockupButton *button in controlsStack)
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
    for (ECMockupButton *button in controlsStack)
        [button setTitleShadowColor:textShadowColor forState:UIControlStateNormal];
}

- (void)setTextShadowOffset:(CGSize)anOffset
{
    textShadowOffset = anOffset;
    searchField.layer.shadowOffset = textShadowOffset;
    for (ECMockupButton *button in controlsStack)
        button.titleLabel.shadowOffset = textShadowOffset;
}

- (void)setBorderColor:(UIColor *)aColor
{
    [borderColor release];
    borderColor = [aColor retain];
    self.layer.borderColor = borderColor.CGColor;
    for (ECMockupButton *button in controlsStack)
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
        [delegate jumpBar:self changedSearchStringTo:aString];
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
    [self->searchField addTarget:self action:@selector(searchFieldAction:) forControlEvents:UIControlEventEditingChanged];
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
    self->minimumStackButtonWidth = 50;
    self->maximumStackButtonWidth = 160;
    self->textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    //
    self.layer.masksToBounds = YES;
    //
    CGPoint origin = self.bounds.origin;
    CGSize size = self.bounds.size;
    origin.x += self->textInsets.left;
    size.width -= self->textInsets.left + self->textInsets.right;
    self->searchField.frame = (CGRect){ origin, size };
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
    [controlsStack release];
    [collapsedButton release];
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    __block CGPoint origin = bounds.origin;
    __block CGSize size = bounds.size;
    CGFloat textPadding = textInsets.left + textInsets.right;
    
    // Calculate maximum usable width for buttons
    CGFloat maxTotWidth = size.width;
    if (minimumSearchFieldWidth < 1.0)
        maxTotWidth *= (1.0 - minimumSearchFieldWidth);
    else
        maxTotWidth -= minimumSearchFieldWidth;
    maxTotWidth -= BUTTON_ARROW_WIDTH + textPadding;
    
    // Collaspe elements
    NSUInteger buttonStackCount = [controlsStack count];
    NSUInteger maxCount = maxTotWidth / minimumStackButtonWidth;
    if (maxCount == 0 || buttonStackCount <= maxCount)
    {
        collapsedRange.length = collapsedRange.location = 0;
        if (collapsedButton)
            collapsedButton.hidden = YES;
    }
    else
    {
        if (!collapsedButton)
            collapsedButton = [[self createStackControlWithTitle:@"..."] retain];
        
        NSRange collapse;
        collapse.location = maxCount / 2 - 1;
        collapse.length = buttonStackCount - maxCount + 1;
        if (!NSEqualRanges(collapse, collapsedRange))
        {
            collapsedRange = collapse;
            collapsedButton.tag = collapsedRange.location + collapsedRange.length;
            
            if (delegateHasDidCollapseToControlCollapsedRange) 
            {
                [delegate jumpBar:self didCollapseToControl:collapsedButton collapsedRange:collapsedRange];
            }
        }
    }
    
    // Calculte button size
    CGSize buttonSize = size;
    if (collapsedRange.length)
        buttonSize.width = maxTotWidth / (buttonStackCount - collapsedRange.length + 1);
    else
        buttonSize.width = maxTotWidth / buttonStackCount;
    if (buttonSize.width < minimumStackButtonWidth)
        buttonSize.width = minimumStackButtonWidth;
    else if (buttonSize.width > maximumStackButtonWidth)
        buttonSize.width = maximumStackButtonWidth;
    buttonSize.width = ceilf(buttonSize.width) + BUTTON_ARROW_WIDTH + textPadding;
    
    // Layout buttons
    CGFloat diff = buttonSize.width - BUTTON_ARROW_WIDTH - textPadding;
    NSUInteger collapseEnd = collapsedRange.location + collapsedRange.length;
    // Hide collapse button if required
    if (collapsedRange.length == 0) 
    {
        collapsedButton.hidden = YES;
    }
    else
    {
        collapsedButton.frame = [[controlsStack objectAtIndex:collapsedRange.location] frame];
    }
    
    [UIView animateWithDuration:0.25 delay:0 options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState |  UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionLayoutSubviews) animations:^(void) {
        UIControl *button;
        for (NSUInteger i = 0; i < buttonStackCount; ++i) 
        {
            button = (UIControl *)[controlsStack objectAtIndex:i];
            if (collapsedRange.length > 0 && i == collapsedRange.location)
            {
                // Layout collapse button
                [self insertSubview:collapsedButton aboveSubview:button];
                CGRect collapsedRect = (CGRect){ origin, buttonSize };
                collapsedButton.hidden = NO;
                collapsedButton.frame = collapsedRect;
                //
                do
                {
                    button.frame = collapsedRect;
                } while (++i < collapseEnd && (button = (UIControl *)[controlsStack objectAtIndex:i]));
                origin.x += diff;
                --i;
            }
            else if (i < collapsedRange.location || i >= collapseEnd)
            {
                // Layout other buttons
                button.hidden = NO;
                button.frame = (CGRect){ origin, buttonSize };
                origin.x += diff;
            }
        }
        
        // Layout search field
        if (buttonStackCount)
            origin.x += BUTTON_ARROW_WIDTH + textPadding;
        origin.x += textInsets.left;
        size.width = bounds.size.width - origin.x - textPadding;
        searchField.frame = (CGRect){ origin, size };
    } completion:^(BOOL finished) {
        for (NSUInteger i = collapsedRange.location; i < collapseEnd; ++i) 
        {
            [[controlsStack objectAtIndex:i] setHidden:YES];
        }
    }];
}

#pragma mark -
#pragma mark Public Methods

- (UIControl *)controlAtStackIndex:(NSUInteger)index
{
    if (index >= [controlsStack count])
        return nil;
    return [controlsStack objectAtIndex:index];
}

- (NSString *)titleOfControlAtStackIndex:(NSUInteger)index
{
    if (index >= [controlsStack count])
        return nil;
    return [[controlsStack objectAtIndex:index] title];
}

- (void)pushControlWithTitle:(NSString *)title
{
    NSUInteger controlsStackCount = [controlsStack count];
    
    // Generate new button
    UIControl *button = [self createStackControlWithTitle:title];
    
    // Set initial frame
    if (controlsStack)
        button.frame = [[controlsStack lastObject] frame];
    else
        button.frame = CGRectMake(-maximumStackButtonWidth, 0, maximumStackButtonWidth, self.bounds.size.height);
    
    // Set convinience informations in tag
    NSUInteger index = controlsStackCount;
    button.tag = index;
    
    // Add button to view
    if (controlsStackCount)
    {
        [self insertSubview:button belowSubview:[controlsStack lastObject]];
    }
    else
    {
        [self insertSubview:button aboveSubview:searchField];
    }
    
    // Add button to stack
    if (!controlsStack)
        controlsStack = [[NSMutableArray alloc] initWithCapacity:10];
    [controlsStack addObject:button];
    
    // Informing delegate
    if (delegateHasDidPushControlAtStackIndex)
    {
        [delegate jumpBar:self didPushControl:button atStackIndex:index];
    }
    
    [self setNeedsLayout];
}

- (void)popControl
{
    UIControl *button = (UIControl *)[controlsStack lastObject];
    if (button) 
    {
        button.hidden = YES;
        [button removeFromSuperview];
        if (delegateHasDidPopControlAtStackIndex) 
        {
            NSUInteger index = [controlsStack indexOfObject:button];
            [controlsStack removeObjectAtIndex:index];
            [delegate jumpBar:self didPopControl:button atStackIndex:index];
        }
        else 
        {
            [controlsStack removeObject:button];
        }
    }
}

- (void)popControlsDownThruIndex:(NSUInteger)index
{
    NSUInteger count = [controlsStack count];
    if (count && count > index) 
    {
        count -= index;
        while (count--)
            [self popControl];
    }
}

#pragma mark -
#pragma mark Private Methods

- (UIControl *)createStackControlWithTitle:(NSString *)title
{
    ECMockupButton *button = [ECMockupButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = self.font;
    button.titleLabel.shadowOffset = self.textShadowOffset;
    button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [button setTitleShadowColor:self.textShadowColor forState:UIControlStateNormal];
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
    [button setBackgroundColor:self.buttonColor forState:UIControlStateNormal];
    [button setBackgroundColor:self.buttonHighlightColor forState:UIControlStateHighlighted];
    button.arrowSizes = UIEdgeInsetsMake(0, 0, 0, BUTTON_ARROW_WIDTH);
    if ([controlsStack count])
        button.titleEdgeInsets = UIEdgeInsetsMake(0, textInsets.left + BUTTON_ARROW_WIDTH, 0, BUTTON_ARROW_WIDTH);
    else
        button.titleEdgeInsets = UIEdgeInsetsMake(0, textInsets.left, 0, BUTTON_ARROW_WIDTH);
    return button;
}

- (void)searchFieldAction:(id)sender
{
    if (delegateHasChangedSearchStringTo) 
    {
        [delegate jumpBar:self changedSearchStringTo:[sender text]];
    }
}

@end
