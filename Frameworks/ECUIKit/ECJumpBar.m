//
//  ECJumpBarView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECJumpBar.h"
#import "ECButton.h"
#import <QuartzCore/QuartzCore.h>

#define BUTTON_ARROW_WIDTH 10

@interface ECJumpBar () {
@private
    UITextField *searchField;
    
    UIControl *collapsedButton;
    NSRange collapsedRange;
    
    BOOL animatePush;
    BOOL animatePop;
    
    BOOL delegateHasDidPushControlAtStackIndex;
    BOOL delegateHasDidPopControlAtStackIndex;
    BOOL delegateHasDidCollapseToControlCollapsedRange;
    BOOL delegateHasChangedSearchStringTo;
}

- (void)searchFieldAction:(id)sender;

@end

@implementation ECJumpBar

#pragma mark - Properties

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
    font = aFont;
    searchField.font = font;
//    for (ECButton *button in controlsStack)
//        button.titleLabel.font = font;
}

- (void)setTextColor:(UIColor *)aColor
{
    textColor = aColor;
    searchField.textColor = textColor;
//    for (ECButton *button in controlsStack)
//        [button setTitleColor:textColor forState:UIControlStateNormal];
}

- (void)setTextShadowColor:(UIColor *)aColor
{
    textShadowColor = aColor;
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
//    for (ECButton *button in controlsStack)
//        [button setTitleShadowColor:textShadowColor forState:UIControlStateNormal];
}

- (void)setTextShadowOffset:(CGSize)anOffset
{
    textShadowOffset = anOffset;
    searchField.layer.shadowOffset = textShadowOffset;
//    for (ECButton *button in controlsStack)
//        button.titleLabel.shadowOffset = textShadowOffset;
}

- (void)setBorderColor:(UIColor *)aColor
{
    borderColor = aColor;
    self.layer.borderColor = borderColor.CGColor;
//    for (ECButton *button in controlsStack)
//        button.borderColor = borderColor;
}

- (void)setBorderWidth:(CGFloat)width
{
    borderWidth = width;
    self.layer.borderWidth = width;
    for (ECButton *button in controlsStack)
        button.borderWidth = borderWidth;
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

#pragma mark - UIView Methods

static void preinit(ECJumpBar *self)
{
    self->searchField = [[UITextField alloc] initWithFrame:CGRectZero];
    self->searchField.backgroundColor = nil;
    self->searchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self->searchField.borderStyle = UITextBorderStyleNone;
    self->searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self->searchField addTarget:self action:@selector(searchFieldAction:) forControlEvents:UIControlEventEditingChanged];
    self.minimumSearchFieldWidth = 0.5;
    self->searchField.text = @"Search";
    //
    //self.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];

    self->minimumStackButtonWidth = 50;
    self->maximumStackButtonWidth = 160;
    self->textInsets = UIEdgeInsetsMake(0, 8, 0, 0);
}

static void init(ECJumpBar *self)
{
    // TODO how to make properties default?
//    self.textColor = [UIColor colorWithHue:0 saturation:0 brightness:0.01 alpha:1];
//    self.textShadowColor = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3];
//    self.textShadowOffset = CGSizeMake(0, 1);
//    self.buttonColor = [UIColor colorWithHue:0 saturation:0 brightness:0.23 alpha:1];
//    self.buttonHighlightColor = [UIColor colorWithRed:93.0/255.0 green:94.0/255.0 blue:94.0/255.0 alpha:1.0];
    self.cornerRadius = 3;
    self.borderColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    self.borderWidth = 1;
    //
    [self addSubview:self->searchField];
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

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    __block CGPoint origin = bounds.origin;
    CGSize size = bounds.size;
    CGFloat textPadding = textInsets.left + textInsets.right;
    
    // Calculate maximum usable width for buttons
    CGFloat maxTotWidth = size.width;
    if (minimumSearchFieldWidth < 1.0)
        maxTotWidth *= (1.0 - minimumSearchFieldWidth);
    else
        maxTotWidth -= minimumSearchFieldWidth;
    maxTotWidth -= BUTTON_ARROW_WIDTH + textPadding;
    
    // Collaspe elements
    // TODO should be done outside layout
    NSUInteger controlsStackCount = [controlsStack count];
    NSUInteger maxCount = maxTotWidth / minimumStackButtonWidth;
    if (maxCount == 0 || controlsStackCount <= maxCount)
    {
        collapsedRange.length = collapsedRange.location = 0;
        if (collapsedButton)
            collapsedButton.hidden = YES;
    }
    else
    {
        if (!collapsedButton)
        {
            collapsedButton = [self createStackControlWithTitle:@"..."];
            collapsedButton.hidden = YES;
            collapsedButton.alpha = 0;
        }
        
        NSRange collapse;
        collapse.location = maxCount / 2 - 1;
        collapse.length = controlsStackCount - maxCount + 1;
        if (!NSEqualRanges(collapse, collapsedRange))
        {
            collapsedRange = collapse;
            collapsedButton.tag = collapsedRange.location + collapsedRange.length;
            
            if (delegateHasDidCollapseToControlCollapsedRange) 
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                    [delegate jumpBar:self didCollapseToControl:collapsedButton collapsedRange:collapsedRange];
                }];
            }
        }
    }
    
    // Calculte button size
    CGSize controlSize = size;
    if (collapsedRange.length)
        controlSize.width = maxTotWidth / (controlsStackCount - collapsedRange.length + 1);
    else
        controlSize.width = maxTotWidth / controlsStackCount;
    if (controlSize.width < minimumStackButtonWidth)
        controlSize.width = minimumStackButtonWidth;
    else if (controlSize.width > maximumStackButtonWidth)
        controlSize.width = maximumStackButtonWidth;
    controlSize.width = ceilf(controlSize.width) + BUTTON_ARROW_WIDTH + textPadding;
    
    // Hide collapse button if required
    if (collapsedRange.length > 0)
    {
        UIControl *firstToCollapse = (UIControl *)[controlsStack objectAtIndex:collapsedRange.location];
        collapsedButton.frame = [firstToCollapse frame];
        [self insertSubview:collapsedButton aboveSubview:firstToCollapse];
    }
    
    // Layout buttons
    CGFloat diff = controlSize.width - BUTTON_ARROW_WIDTH - textPadding;
    void (^actualLayout)() = ^{
        __block CGRect collapsedRect = CGRectZero;
        NSUInteger controlsStackActualCount = controlsStackCount - (NSUInteger)animatePush;
        [controlsStack enumerateObjectsUsingBlock:^(UIControl *control, NSUInteger i, BOOL *stop) {
            // Exit if pushing
            if (i == controlsStackActualCount)
            {
                *stop = YES;
            }
            // Layout collapsed controls
            else if (NSLocationInRange(i, collapsedRange))
            {
                // Layout collapse control
                if (i == collapsedRange.location)
                {
                    collapsedRect = (CGRect){ origin, controlSize };
                    collapsedButton.hidden = NO;
                    collapsedButton.alpha = 1.0;                
                    collapsedButton.frame = collapsedRect;
                    origin.x += diff;
                }
                control.frame = collapsedRect;
            }
            // Layout non-collapsed controls
            else
            {
                control.hidden = NO;
                control.alpha = 1.0;
                control.frame = (CGRect){ origin, controlSize };
                origin.x += diff;
            }
        }];
        // Layout search field
        CGPoint searchOrigin = origin;
        if (controlsStackActualCount > 0)
            searchOrigin.x += BUTTON_ARROW_WIDTH + textPadding;
        searchOrigin.x += textInsets.left;
        searchOrigin.y += 1;
        searchField.frame = (CGRect){ searchOrigin, { bounds.size.width - searchOrigin.x - textPadding, size.height } };
    };
    
    void (^actualLayoutCleanup)() = ^ {
        // Hide collapsed buttons
        if (collapsedRange.length == 0) 
        {
            collapsedButton.hidden = YES;
        }
        else
        {
            [controlsStack enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:collapsedRange] options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [obj setHidden:YES];
            }];
        }
    };
    
    if (animatePush || animatePop)
    {
        [UIView animateWithDuration:0.15 delay:0 options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews) animations:actualLayout completion:^(BOOL finished) {
            // Cleanup
            actualLayoutCleanup();
            // Animate pushed button
            if (animatePush) 
            {
                // Prepare pushed control frame
                UIControl *pushed = (UIControl *)[controlsStack lastObject];
                // Animate into position
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionLayoutSubviews animations:^(void) {
                    pushed.alpha = 1.0;
                    pushed.frame = (CGRect){ origin, controlSize };
                    searchField.frame = (CGRect){ 
                        { origin.x + textInsets.left + textPadding + BUTTON_ARROW_WIDTH, origin.y }, 
                        { bounds.size.width - origin.x - textPadding, size.height } };
                } completion:nil];
                animatePush = NO;
            }
            animatePop = NO;
        }];
    }
    else
    {
        actualLayout();
        actualLayoutCleanup();
    }
}

#pragma mark - Public Methods

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

- (void)pushControlWithTitle:(NSString *)title animated:(BOOL)animated
{
    animatePush = animated;
    NSUInteger controlsStackCount = [controlsStack count];
    
    // Generate new control
    UIControl *control = [self createStackControlWithTitle:title];
    if (animatePush) 
    {
        control.hidden = YES;
        control.alpha = 0.0;
        UIControl *last = (UIControl *)[controlsStack lastObject];
        if (last)
            control.frame = last.frame;
        else
            control.frame = CGRectMake(-maximumStackButtonWidth, 0, maximumStackButtonWidth, self.bounds.size.height);
    }
    
    // Set convinience informations in tag
    NSUInteger index = controlsStackCount;
    control.tag = index;
    
    // Add button to stack
    if (!controlsStack)
        controlsStack = [[NSMutableArray alloc] initWithCapacity:10];
    [controlsStack addObject:control];
    
    // Add button to view
    if (controlsStackCount)
    {
        [self insertSubview:control belowSubview:[controlsStack objectAtIndex:controlsStackCount - 1]];
    }
    else
    {
        [self insertSubview:control aboveSubview:searchField];
    }
    
    // Informing delegate
    if (delegateHasDidPushControlAtStackIndex)
    {
        [delegate jumpBar:self didPushControl:control atStackIndex:index];
    }
    
    [self layoutIfNeeded];
}

- (void)popControlAnimated:(BOOL)animated
{
    UIControl *control = (UIControl *)[controlsStack lastObject];
    if (control) 
    {
        // Remove control from view hierarchy
        animatePop = animated;
        if (animatePop) 
        {
            CGRect newFrame;
            NSUInteger controlsStackCount = [controlsStack count];
            if (controlsStackCount > 1)
                newFrame = [[controlsStack objectAtIndex:controlsStackCount - 2] frame];
            else
                newFrame = CGRectMake(-maximumStackButtonWidth, 0, maximumStackButtonWidth, self.bounds.size.height);
            // Animate out
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction animations:^(void) {
                control.alpha = 0.0;
                control.frame = newFrame;
            } completion:^(BOOL finished) {
                control.hidden = YES;
                [control removeFromSuperview];
            }];
        }
        else
        {
            control.hidden = YES;
            [control removeFromSuperview];
        }
        // Notify delegate and remove from internal stack
        if (delegateHasDidPopControlAtStackIndex) 
        {
            NSUInteger index = [controlsStack indexOfObject:control];
            [controlsStack removeObjectAtIndex:index];
            [delegate jumpBar:self didPopControl:control atStackIndex:index];
        }
        else 
        {
            [controlsStack removeObject:control];
        }
    }
}

- (void)popControlsDownThruIndex:(NSUInteger)index animated:(BOOL)animated
{
    NSUInteger count = [controlsStack count];
    if (count && count > index) 
    {
        count -= index;
        while (count--)
            [self popControlAnimated:animated];
    }
}

#pragma mark - Private Methods

- (UIControl *)createStackControlWithTitle:(NSString *)title
{
    ECButton *button = [ECButton new];
    button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    button.contentMode = UIViewContentModeScaleToFill;
    button.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = self.font;
    button.titleLabel.shadowOffset = self.textShadowOffset;
    button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [button setTitleShadowColor:self.textShadowColor forState:UIControlStateNormal];
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
    [button setBackgroundColor:self.buttonColor forState:UIControlStateNormal];
    [button setBackgroundColor:self.buttonHighlightColor forState:UIControlStateHighlighted];
    button.rightArrowSize = BUTTON_ARROW_WIDTH;
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
