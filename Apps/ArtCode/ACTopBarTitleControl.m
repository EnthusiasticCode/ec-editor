//
//  ACTopBarTitleControl.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTopBarTitleControl.h"


@interface ACTopBarTitleControl () {
    NSArray *_preViews;
    NSArray *_postViews;
    NSArray *_currentViews;
    
    UIActivityIndicatorView *_activityIndicatorView;
}

- (void)_setupTitle;
- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes isPrimary:(BOOL)isPrimary;

@end


@implementation ACTopBarTitleControl

#pragma mark - Properties

@synthesize backgroundButton;
@synthesize loadingMode;
@synthesize titleFragments, selectedTitleFragments;
@synthesize selectedTitleFragmentsTint, secondaryTitleFragmentsTint, gapBetweenFragments, contentInsets;
@synthesize selectedFragmentFont, secondaryFragmentFont;

- (UIButton *)backgroundButton
{
    if (!backgroundButton)
    {
        backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self insertSubview:backgroundButton atIndex:0];
    }
    return backgroundButton;
}

- (void)setTitleFragments:(NSArray *)fragments selectedIndexes:(NSIndexSet *)selected
{
    BOOL changeFragments = (fragments != titleFragments);
    BOOL changeSelection = (selected != selectedTitleFragments);
    if (!changeFragments && !changeSelection)
        return;
    
    if (changeFragments)
        [self willChangeValueForKey:@"titleFragments"];

    if (changeSelection)
        [self willChangeValueForKey:@"selectedTitleFragments"];
    
    titleFragments = fragments;
    selectedTitleFragments = selected;
    [self _setupTitle];
    
    if (changeFragments)
        [self didChangeValueForKey:@"titleFragments"];
    
    if (changeSelection)
        [self didChangeValueForKey:@"selectedTitleFragments"];
}

- (UIColor *)secondaryTitleFragmentsTint
{
    if (!secondaryTitleFragmentsTint)
        secondaryTitleFragmentsTint = [UIColor grayColor];
    return secondaryTitleFragmentsTint;
}

- (void)setSecondaryTitleFragmentsTint:(UIColor *)tint
{
    if (tint == secondaryTitleFragmentsTint)
        return;
    
    [self willChangeValueForKey:@"secondaryTitleFragmentsTint"];
    secondaryTitleFragmentsTint = tint;
    [self _setupTitle];
    [self didChangeValueForKey:@"secondaryTitleFragmentsTint"];
}

- (UIFont *)selectedFragmentFont
{
    if (selectedFragmentFont == nil)
        selectedFragmentFont = [UIFont boldSystemFontOfSize:20];
    return selectedFragmentFont;
}

- (void)setSelectedFragmentFont:(UIFont *)font
{
    if (font == selectedFragmentFont)
        return;
    
    [self willChangeValueForKey:@"selectedFragmentFont"];
    selectedFragmentFont = font;
    [self _setupTitle];
    [self didChangeValueForKey:@"selectedFragmentFont"];
}

- (UIFont *)secondaryFragmentFont
{
    if (secondaryFragmentFont == nil)
        secondaryFragmentFont = [UIFont systemFontOfSize:14];
    return secondaryFragmentFont;
}

- (void)setSecondaryFragmentFont:(UIFont *)font
{
    if (font == secondaryFragmentFont)
        return;
    
    [self willChangeValueForKey:@"secondaryFragmentFont"];
    secondaryFragmentFont = font;
    [self _setupTitle];
    [self didChangeValueForKey:@"secondaryFragmentFont"];
}

- (void)setLoadingMode:(BOOL)mode
{
    if (mode == loadingMode)
        return;
    
    [self willChangeValueForKey:@"loadingMode"];
    
    loadingMode = mode;
    
    if (loadingMode)
    {
        if (!_activityIndicatorView)
        {
            _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        }
        [self addSubview:_activityIndicatorView];
        _activityIndicatorView.center = CGPointMake(20, self.bounds.size.height / 2);
        [_activityIndicatorView startAnimating];
    }
    else
    {
        [_activityIndicatorView stopAnimating];
        [_activityIndicatorView removeFromSuperview];
    }
    
    [self didChangeValueForKey:@"loadingMode"];
}

- (void)setContentInsets:(UIEdgeInsets)value
{
    if (UIEdgeInsetsEqualToEdgeInsets(value, contentInsets))
        return;
    [self willChangeValueForKey:@"contentInsets"];
    contentInsets = value;
    [self setNeedsLayout];
    [self didChangeValueForKey:@"contentInsets"];
}

#pragma mark - View Methods

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    self.backgroundButton.frame = bounds;
    bounds = UIEdgeInsetsInsetRect(bounds, self.contentInsets);
    
    CGRect labelFrame = CGRectZero;
    for (UIView *view in _currentViews)
    {
        [view sizeToFit];
        labelFrame.size.width += view.bounds.size.width + gapBetweenFragments;
    }
    labelFrame.size.width -= gapBetweenFragments;
    labelFrame.size.height = bounds.size.height;
    labelFrame.origin = CGPointMake( self.contentInsets.left + (bounds.size.width - labelFrame.size.width) / 2.0, self.contentInsets.top + (bounds.size.height - labelFrame.size.height) / 2.0);
    
    // Selected, current views layout
    CGRect viewFrame, lastViewFrame = labelFrame;
    lastViewFrame.size = CGSizeZero;
    for (UIView *view in _currentViews)
    {
        viewFrame = view.frame;
        viewFrame.origin = CGPointMake(CGRectGetMaxX(lastViewFrame), labelFrame.origin.y + (labelFrame.size.height - viewFrame.size.height) / 2.0);
        lastViewFrame = CGRectIntegral(viewFrame);
        view.frame = lastViewFrame;
        lastViewFrame.origin.x += gapBetweenFragments;
    }
    
    CGFloat maxSegmentWidth = (bounds.size.width - labelFrame.size.width) / 2.0 - gapBetweenFragments;
    
    // Pre views layout
    lastViewFrame = labelFrame;
    for (UIView *view in [_preViews reverseObjectEnumerator])
    {
        [view sizeToFit];
        viewFrame = view.frame;
        if (viewFrame.size.width > maxSegmentWidth)
            viewFrame.size.width = maxSegmentWidth;
        viewFrame.origin = CGPointMake(lastViewFrame.origin.x - viewFrame.size.width - gapBetweenFragments, labelFrame.origin.y + (labelFrame.size.height - viewFrame.size.height) / 2.0);
        
        lastViewFrame = CGRectIntegral(viewFrame);
        view.frame = lastViewFrame;
    }
    
    // Post views layout
    lastViewFrame = labelFrame;
    for (UIView *view in _postViews)
    {
        [view sizeToFit];
        viewFrame = view.frame;
        if (viewFrame.size.width > maxSegmentWidth)
            viewFrame.size.width = maxSegmentWidth;
        viewFrame.origin = CGPointMake(CGRectGetMaxX(lastViewFrame) + gapBetweenFragments, labelFrame.origin.y + (labelFrame.size.height - viewFrame.size.height) / 2.0);
        
        lastViewFrame = CGRectIntegral(viewFrame);
        view.frame = lastViewFrame;
    }
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state
{
    [self.backgroundButton setBackgroundImage:image forState:state];
}

- (UIImage *)backgroundImageForState:(UIControlState)state
{
    return [self.backgroundButton backgroundImageForState:state];
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    ECASSERT(0 && "Should not be called, use titleFragments instead");
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    ECASSERT(0 && "Should not be called, use titleFragments instead");
}

#pragma mark - Private Methods

- (void)_setupTitle
{
    if (![titleFragments count])
        return;
    
    NSIndexSet *selected = selectedTitleFragments ? selectedTitleFragments : [NSIndexSet indexSetWithIndex:[titleFragments count] - 1];
    
    [_preViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _preViews = ([selected firstIndex] > 0) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [selected firstIndex])] isPrimary:NO] : nil;
    
    [_postViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _postViews = ([selected lastIndex] + 1 < [titleFragments count]) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([selected lastIndex] + 1, [titleFragments count] - [selected lastIndex] - 1) ] isPrimary:NO] : nil;
    
    [_currentViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _currentViews = [selected count] ? [self _setupViewArrayFromTitleFragmentIndexes:selected isPrimary:YES] : nil;
}

- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes isPrimary:(BOOL)isPrimary
{
    if ([fragmentIndexes count] == 0)
        return nil;
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[fragmentIndexes count]];
    [titleFragments enumerateObjectsAtIndexes:fragmentIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]])
        {
            UILabel *label = [UILabel new];
            label.lineBreakMode = UILineBreakModeMiddleTruncation;
            label.backgroundColor = [UIColor clearColor];
            
            label.textColor = isPrimary ? self.selectedTitleFragmentsTint : self.secondaryTitleFragmentsTint;
            label.font = isPrimary ? self.selectedFragmentFont : self.secondaryFragmentFont;
            
            label.shadowColor = [UIColor colorWithWhite:0.1 alpha:1];
            
            label.text = (NSString *)obj;
            [result addObject:label];
        }
        else if ([obj isKindOfClass:[UIImage class]])
        {
            [result addObject:[[UIImageView alloc] initWithImage:(UIImage *)obj]];
        }
        else if ([obj isKindOfClass:[UIView class]])
        {
            [result addObject:obj];
        }
        else return;
        [self addSubview:[result lastObject]];
    }];
    return result;
}

@end
