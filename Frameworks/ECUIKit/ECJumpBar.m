//
//  ECJumpBarView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECJumpBar.h"
#import <QuartzCore/QuartzCore.h>

#define BUTTON_ARROW_WIDTH 10

@interface ECJumpBar () {
@private
    NSMutableArray *jumpElements;
    
    struct {
        unsigned int hasCreateElementForJumpPathComponentIndex : 1;
        unsigned int hasPathComponentForJumpElementIndex : 1;
        unsigned int hasCanCollapseJumpElementIndex : 1;
        unsigned int reserved : 1;
    } delegateFlags;
}

- (NSIndexSet *)visibleElementsIndexSet;
- (void)layoutElementsWithIndexes:(NSIndexSet *)elementIndexes;

@end


@implementation ECJumpBar

#pragma mark - Properties

@synthesize delegate;

- (void)setDelegate:(id<ECJumpBarDelegate>)aDelegate
{
    delegate = aDelegate;

    delegateFlags.hasCreateElementForJumpPathComponentIndex = [delegate respondsToSelector:@selector(jumpBar:createElementForJumpPathComponent:index:)];
    delegateFlags.hasPathComponentForJumpElementIndex = [delegate respondsToSelector:@selector(jumpBar:pathComponentForJumpElement:index:)];
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
        collapseElement = [self createDefaultElementForJumpPathComponent:@"..."];
        collapseElement.frame = CGRectMake(0, 0, minimumJumpElementWidth, 0);
    }
    return collapseElement;
}

#pragma mark - UIView Methods

static void preinit(ECJumpBar *self)
{
    self->jumpElements = [NSMutableArray new];
    
    self->minimumTextElementWidth = 0.5;
    
    self->minimumJumpElementWidth = 50;
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
    NSIndexSet *visibleElements = [self visibleElementsIndexSet];
    BOOL anyElement = ([visibleElements count] > 0);
    
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
    
    [self layoutElementsWithIndexes:visibleElements];
    
    CGFloat lastElementEnd = anyElement ? roundf(CGRectGetMaxX([[jumpElements objectAtIndex:[visibleElements lastIndex]] frame])) : 0;
    self.textElement.frame = CGRectMake(lastElementEnd, 0, bounds.size.width - lastElementEnd, bounds.size.height);
}

#pragma mark - Jump Element Related Methods

- (UIView *)createDefaultElementForJumpPathComponent:(NSString *)pathComponent
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:pathComponent forState:UIControlStateNormal];
    return button;
}

- (void)pushJumpElementsForPath:(NSString *)path animated:(BOOL)animated
{
    UIView *element = delegateFlags.hasCreateElementForJumpPathComponentIndex 
    ? [delegate jumpBar:self createElementForJumpPathComponent:path index:[jumpElements count]]
    : [self createDefaultElementForJumpPathComponent:path];
    
    [jumpElements addObject:element];
    
    [self setNeedsLayout];
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
    
    // Calculate actual jump elments limit sizes
    CGFloat minElementWidth = minimumJumpElementWidth + jumpElementMargins.left + jumpElementMargins.right;
    CGFloat maxElementWidth = maximumJumpElementWidth + jumpElementMargins.left + jumpElementMargins.right;
    
    // Calculate first element frame
    CGFloat elementWidth = MAX(minElementWidth, MIN(maxElementWidth, availableElementsSpace / (CGFloat)[elementIndexes count]));
    __block CGRect elementFrame = (CGRect){
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
            
            elementFrame.origin.x += roundf(collapseElementFrame.size.width + jumpElementMargins.left + jumpElementMargins.right);
            
            findHole = NSNotFound;
        }
        // Insert subview
        [self insertSubview:element belowSubview:lastSubview];
        lastSubview = element;
        // Position jump element
        element.frame = elementFrame;
        elementFrame.origin.x += roundf(elementFrame.size.width + jumpElementMargins.left + jumpElementMargins.right);
    }];
}

@end
