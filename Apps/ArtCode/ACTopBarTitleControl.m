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
    
    UIActivityIndicatorView *_activityIndicatorView;
}

- (void)_setupTitle;
- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes;

@end


@implementation ACTopBarTitleControl

#pragma mark - Properties

@synthesize loadingMode;
@synthesize titleFragments, selectedTitleFragments;
@synthesize secondaryTitleFragmentsTint, gapBetweenFragments, contentInsets;
@synthesize secondaryFragmentFont;

- (void)setTitleFragments:(NSArray *)fragments
{
    if (fragments == titleFragments)
        return;
    
    [self willChangeValueForKey:@"titleFragments"];
    titleFragments = fragments;
    [self _setupTitle];
    [self didChangeValueForKey:@"titleFragments"];
}

- (void)setSelectedTitleFragments:(NSIndexSet *)fragments
{
    ECASSERT([fragments lastIndex] < [titleFragments count]);
    
    if (fragments == selectedTitleFragments)
        return;
    
    [self willChangeValueForKey:@"selectedTitleFragments"];
    selectedTitleFragments = fragments;
    [self _setupTitle];
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
    return self.titleLabel.font;
}

- (void)setSelectedFragmentFont:(UIFont *)font
{
    if (font == self.selectedFragmentFont)
        return;
    
    [self willChangeValueForKey:@"selectedFragmentFont"];
    self.titleLabel.font = font;
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
//        UIImage *loadingBackgroundImage = [self backgroundImageForState:ACControlStateLoading];
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

#pragma mark - View Methods

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    CGRect labelFrame = self.titleLabel.text ? self.titleLabel.frame : CGRectNull;
    if (self.imageView.image)
        labelFrame = CGRectUnion(labelFrame, self.imageView.frame);
    
    CGFloat maxSegmentWidth = (bounds.size.width - labelFrame.size.width) / 2 - gapBetweenFragments;
    
    // Pre views layout
    CGRect lastViewFrame = labelFrame;
    for (UIView *view in [_preViews reverseObjectEnumerator])
    {
        [view sizeToFit];
        CGRect viewFrame = view.frame;
        if (viewFrame.size.width > maxSegmentWidth - contentInsets.left)
            viewFrame.size.width = maxSegmentWidth - contentInsets.left;
        viewFrame.origin = CGPointMake(lastViewFrame.origin.x - viewFrame.size.width - gapBetweenFragments, labelFrame.origin.y + (labelFrame.size.height - viewFrame.size.height) / 2);
        
        lastViewFrame = CGRectIntegral(viewFrame);
        view.frame = lastViewFrame;
    }
    
    // Post views layout
    lastViewFrame = labelFrame;
    for (UIView *view in _postViews)
    {
        [view sizeToFit];
        CGRect viewFrame = view.frame;
        if (viewFrame.size.width > maxSegmentWidth - contentInsets.right)
            viewFrame.size.width = maxSegmentWidth - contentInsets.right;
        viewFrame.origin = CGPointMake(CGRectGetMaxX(lastViewFrame) + gapBetweenFragments, labelFrame.origin.y + (labelFrame.size.height - viewFrame.size.height) / 2);
        
        lastViewFrame = CGRectIntegral(viewFrame);
        view.frame = lastViewFrame;
    }
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
    NSIndexSet *selected = selectedTitleFragments ? selectedTitleFragments : [NSIndexSet indexSetWithIndex:[titleFragments count] - 1];
    
    [_preViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _preViews = ([selected firstIndex] > 0) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [selected firstIndex])]] : nil;
    
    [_postViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _postViews = ([selected lastIndex] + 1 < [titleFragments count]) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([selected lastIndex] + 1, [titleFragments count] - [selected lastIndex] - 1)]] : nil;
    
    [super setTitle:nil forState:UIControlStateNormal];
    [super setImage:nil forState:UIControlStateNormal];
    [titleFragments enumerateObjectsAtIndexes:selected options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]])
        {
            [super setTitle:(NSString *)obj forState:UIControlStateNormal];
            self.titleLabel.shadowColor = [UIColor blackColor];
            self.titleLabel.shadowOffset = CGSizeMake(0, -1);
        }
        else if ([obj isKindOfClass:[UIImage class]])
        {
            [super setImage:(UIImage *)obj forState:UIControlStateNormal];
        }
    }];
}

- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes
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
            
            label.textColor = self.secondaryTitleFragmentsTint;
            label.font = self.secondaryFragmentFont;
            
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
