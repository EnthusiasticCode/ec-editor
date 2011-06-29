//
//  ECJumpBarView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECJumpBar.h"
#import <QuartzCore/QuartzCore.h>


@implementation ECJumpBar {
    NSMutableArray *jumpElements;
    
    /// Variable keeping the current visible elements. It is updated only in the
    /// pushJumpElementWithPathComponent:animated:.
    NSIndexSet *visibleJumpElements;
    
    struct {
        unsigned int hasCanCollapseJumpElementIndex : 1;
        unsigned int reserved : 3;
    } delegateFlags;
}

#pragma mark - Properties

@synthesize delegate;

- (void)setDelegate:(id<ECJumpBarDelegate>)aDelegate
{
    delegate = aDelegate;

    delegateFlags.hasCanCollapseJumpElementIndex = [delegate respondsToSelector:@selector(jumpBar:canCollapseJumpElement:index:)];
}

@synthesize backgroundView;

- (void)setBackgroundView:(UIView *)view
{
    [backgroundView removeFromSuperview];
    backgroundView = view;
    [self addSubview:backgroundView];
}

@synthesize backElement;

- (void)setBackElement:(UIView *)view
{
    [backElement removeFromSuperview];
    backElement = view;
    [self addSubview:backElement];
}

@synthesize textElement, minimumTextElementWidth;

- (UITextView *)textElement
{
    if (!textElement)
    {
        textElement = [UITextView new];
        [self addSubview:textElement];
    }
    return textElement;
}

- (void)setTextElement:(UITextView *)view
{
    [textElement removeFromSuperview];
    textElement = view;
    [self addSubview:textElement];
}

@synthesize jumpElements, minimumJumpElementWidth, maximumJumpElementWidth, jumpElementMargins;
@synthesize collapseElement;

- (UIView *)collapseElement
{
    if (!collapseElement)
    {
        collapseElement = [delegate jumpBar:self createElementForJumpPathComponent:@"..." index:NSNotFound];
        collapseElement.frame = CGRectMake(0, 0, minimumJumpElementWidth, 0);
    }
    return collapseElement;
}

#pragma mark - Private Methods

- (NSIndexSet *)visibleElementsIndexSet
{
    NSUInteger jumpElementsCount = [jumpElements count];
    if (jumpElementsCount == 0)
        return nil;
    
    CGSize boundsSize = self.bounds.size;
    CGFloat availableElementsSpace = boundsSize.width;
    availableElementsSpace -= (minimumTextElementWidth < 1. ? minimumTextElementWidth * boundsSize.width : minimumTextElementWidth);
    if (backElement)
        availableElementsSpace -= backElement.bounds.size.width;
    
    // TODO may require additional step if shouldResizeJumpElement is used
    
    CGFloat minElementWidth = minimumJumpElementWidth + jumpElementMargins.left + jumpElementMargins.right;
    
    NSMutableIndexSet *visibleElementsIndexSet = [NSMutableIndexSet indexSet];
    
    // Retrieve non-collapsed elements
    NSUInteger allowedElementCount = availableElementsSpace / minElementWidth;
    if (allowedElementCount < jumpElementsCount)
    {
        availableElementsSpace -= self.collapseElement.bounds.size.width + jumpElementMargins.left + jumpElementMargins.right;
        allowedElementCount = availableElementsSpace / minElementWidth;
        
        if (delegateFlags.hasCanCollapseJumpElementIndex)
        {
            __block NSUInteger elementsCount = 0;
            __block NSUInteger remainingElementCount = jumpElementsCount;
            [jumpElements enumerateObjectsUsingBlock:^(UIView *element, NSUInteger idx, BOOL *stop) {
                // Force add if enough space remaining
                if (remainingElementCount <= allowedElementCount - elementsCount)
                {
                    *stop = YES;
                    return;
                }
                // Ask delegate if element cannot be collapsed
                if (![delegate jumpBar:self canCollapseJumpElement:element index:idx])
                {
                    elementsCount++;
                    // Stop non-collapsing if running out of space
                    if (elementsCount == allowedElementCount)
                    {
                        elementsCount--;
                        *stop = YES;
                        return;
                    }
                    [visibleElementsIndexSet addIndex:idx];
                }
                remainingElementCount--;
            }];
            
            // Add remaining elements
            if (allowedElementCount > elementsCount)
                [visibleElementsIndexSet addIndexesInRange:(NSRange){ jumpElementsCount - (allowedElementCount - elementsCount), allowedElementCount - elementsCount }];
        }
        else
        {
            // Automatic collapsing, will keep the first element and the lasts
            [visibleElementsIndexSet addIndex:0];
            [visibleElementsIndexSet addIndexesInRange:(NSRange){ 
                jumpElementsCount - (allowedElementCount - 1), 
                allowedElementCount - 1 
            }];
        }
    }
    else
    {
        [visibleElementsIndexSet addIndexesInRange:(NSRange){ 0, jumpElementsCount }];
    }
    
    return visibleElementsIndexSet;
}

- (void)layoutElementsWithIndexes:(NSIndexSet *)elementIndexes;
{
    if (elementIndexes == nil)
        return;
    
    BOOL shouldCollapse = ([jumpElements count] != [elementIndexes count]);
    
    // Calculate available space for jump elements
    CGSize boundsSize = self.bounds.size;
    CGFloat availableElementsSpace = boundsSize.width;
    availableElementsSpace -= (minimumTextElementWidth < 1. ? minimumTextElementWidth * boundsSize.width : minimumTextElementWidth);
    if (backElement)
        availableElementsSpace -= backElement.bounds.size.width;
    if (shouldCollapse)
        availableElementsSpace -= self.collapseElement.bounds.size.width + jumpElementMargins.left + jumpElementMargins.right;
        
    // Calculate first element frame
    CGFloat elementWidth = roundf(MAX(minimumJumpElementWidth, 
                                  MIN(maximumJumpElementWidth, 
                                      (availableElementsSpace / (CGFloat)([elementIndexes count] + shouldCollapse) - jumpElementMargins.left - jumpElementMargins.right))));
    __block CGRect elementFrame = (CGRect) {
        { (backElement ? backElement.bounds.size.width : 0) + jumpElementMargins.left },
        { elementWidth, boundsSize.height }
    };
    
    // layout elements
    __block NSUInteger findHole = 0;
    __block UIView *lastSubview = backElement ? backElement : self.textElement;
    [jumpElements enumerateObjectsAtIndexes:elementIndexes options:0 usingBlock:^(UIView *element, NSUInteger idx, BOOL *stop) {
        // Account for collapse element
        if (findHole != NSNotFound && idx != findHole++)
        {
            [self insertSubview:collapseElement belowSubview:lastSubview];
            lastSubview = collapseElement;
            
            CGRect collapseElementFrame = collapseElement.frame;
            collapseElementFrame.origin = elementFrame.origin;
            collapseElementFrame.size.height = elementFrame.size.height;
            collapseElement.frame = collapseElementFrame;
            
            elementFrame.origin.x += (collapseElementFrame.size.width + jumpElementMargins.left + jumpElementMargins.right);
            
            findHole = NSNotFound;
        }
        // Insert subview
        [self insertSubview:element belowSubview:lastSubview];
        lastSubview = element;
        // Position jump element
        element.frame = elementFrame;
        elementFrame.origin.x += (elementFrame.size.width + jumpElementMargins.left + jumpElementMargins.right);
    }];
}

#pragma mark - UIView Methods

static void preinit(ECJumpBar *self)
{
    self->jumpElements = [NSMutableArray new];
    
    self->minimumTextElementWidth = 0.5;
    
    self->minimumJumpElementWidth = 80;
    self->maximumJumpElementWidth = 160;
}

static void init(ECJumpBar *self)
{
    self.layer.masksToBounds = YES;
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
    BOOL anyElement = ([visibleJumpElements count] > 0);
    
    if (backgroundView)
        backgroundView.frame = (CGRect){ CGPointZero, bounds.size };
    
    if (backElement)
    {
        if (anyElement)
        {
            backElement.hidden = NO;
            backElement.frame = (CGRect){ CGPointZero, { backElement.frame.size.width, bounds.size.height } };
        }
        else
        {
            backElement.hidden = YES;
        }
    }
    
    [self layoutElementsWithIndexes:visibleJumpElements];
    
    CGFloat lastElementEnd = anyElement ? (CGRectGetMaxX([[jumpElements objectAtIndex:[visibleJumpElements lastIndex]] frame])) : 0;
    self.textElement.frame = CGRectMake(lastElementEnd, 0, bounds.size.width - lastElementEnd, bounds.size.height);
}

#pragma mark - Jump Element Related Methods

- (void)pushJumpElementsForPath:(NSString *)path animated:(BOOL)animated
{
    // Create and add new
    UIView *element = [delegate jumpBar:self createElementForJumpPathComponent:path index:[jumpElements count]];
    if (!element)
        return;
    
    [jumpElements addObject:element];
    
    // Calculate visible and collapsed elements indexes
    visibleJumpElements = [self visibleElementsIndexSet];
    NSUInteger jumpElementsCount = [jumpElements count];
    NSMutableIndexSet *collapsedElements = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, jumpElementsCount)];
    [collapsedElements removeIndexes:visibleJumpElements];
    
    if (animated)
    {
        // Prepare elements for animation
        element.alpha = 0;
        if (jumpElementsCount == 1)
        {
            element.frame = CGRectMake(-maximumJumpElementWidth, 0, maximumJumpElementWidth, self.bounds.size.height);
        }
        if ([collapsedElements count] && !self.collapseElement.superview)
        {
            collapseElement.frame = [[jumpElements objectAtIndex:[collapsedElements firstIndex]] frame];
            collapseElement.alpha = 0;
        }
        // Animate
        __block CGRect elementFrame;
        __block CGRect elementPreAnimationFrame;
        [UIView animateWithDuration:0.15 animations:^(void) {
            [self layoutSubviews];
            if (jumpElementsCount > 1)
            {
                elementFrame = element.frame;
                elementPreAnimationFrame = elementFrame;
                elementPreAnimationFrame.origin.x -= elementFrame.size.width;
                element.frame = elementPreAnimationFrame;
                //
                collapseElement.alpha = 1;
                //
                [jumpElements enumerateObjectsAtIndexes:collapsedElements options:0 usingBlock:^(UIView *e, NSUInteger idx, BOOL *stop) {
                    e.frame = collapseElement.frame;
                }];
            }
            else
            {
                element.alpha = 1;
            }
        } completion:^(BOOL finished) {
            if (jumpElementsCount > 1)
            {
                element.frame = elementPreAnimationFrame;
                [UIView animateWithDuration:0.15 animations:^(void) {
                    element.alpha = 1;
                    element.frame = elementFrame;
                }];
                // Remove collapsed elements from view hierarchy
                [jumpElements enumerateObjectsAtIndexes:collapsedElements options:0 usingBlock:^(UIView *e, NSUInteger idx, BOOL *stop) {
                    [e removeFromSuperview];
                }];
            }
        }];
    }
    else
    {
        [self setNeedsLayout];
        // Remove collapsed elements from view hierarchy
        [jumpElements enumerateObjectsAtIndexes:collapsedElements options:0 usingBlock:^(UIView *element, NSUInteger idx, BOOL *stop) {
            [element removeFromSuperview];
        }];
    }
}

- (void)popJumpElementAnimated:(BOOL)animated
{
    UIView *element = [jumpElements lastObject];
    [jumpElements removeLastObject];
    
    // Calculate visible and collapsed elements indexes
    visibleJumpElements = [self visibleElementsIndexSet];
    NSUInteger jumpElementsCount = [jumpElements count];
    NSMutableIndexSet *collapsedElements = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, jumpElementsCount)];
    [collapsedElements removeIndexes:visibleJumpElements];
    
    if (animated)
    {
        [UIView animateWithDuration:0.15 animations:^(void) {
            element.alpha = 0;
            CGRect elementFrame = element.frame;
            elementFrame.origin.x -= elementFrame.size.width;
            element.frame = elementFrame;
            //
//            CGRect textElementFrame = textElement.frame;
//            textElementFrame.origin.x -= elementFrame.size.width + jumpElementMargins.left + jumpElementMargins.right;
//            textElementFrame.size.width += elementFrame.size.width; // TODO triggers layout subview. why?
//            textElement.frame = textElementFrame;
        } completion:^(BOOL finished) {
            [element removeFromSuperview];
            [UIView animateWithDuration:0.15 animations:^(void) {
                [self layoutSubviews];
                if (![collapsedElements count])
                    collapseElement.alpha = 0;
            } completion:^(BOOL finished) {
                if (![collapsedElements count])
                {
                    collapseElement.alpha = 1;
                    [collapseElement removeFromSuperview];
                }
            }];
        }];
    }
    else
    {    
        if (![collapsedElements count])
            [collapseElement removeFromSuperview];
        
        [element removeFromSuperview];
        
        [self setNeedsLayout];
    }
}

@end
