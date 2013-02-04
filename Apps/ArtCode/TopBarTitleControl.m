//
//  TopBarTitleControl.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TopBarTitleControl.h"


@interface TopBarTitleControl () {
  NSArray *_preViews;
  NSArray *_postViews;
  NSArray *_currentViews;
  
  UIActivityIndicatorView *_activityIndicatorView;
}

- (void)_setupTitle;
- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes isPrimary:(BOOL)isPrimary;

@end


@implementation TopBarTitleControl

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
    backgroundButton.isAccessibilityElement = NO;
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
    secondaryTitleFragmentsTint = UIColor.grayColor;
  return secondaryTitleFragmentsTint;
}

- (void)setSecondaryTitleFragmentsTint:(UIColor *)tint
{
  if (tint == secondaryTitleFragmentsTint)
    return;
  
  secondaryTitleFragmentsTint = tint;
  [self _setupTitle];
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
  
  selectedFragmentFont = font;
  [self _setupTitle];
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
  
  secondaryFragmentFont = font;
  [self _setupTitle];
}

- (void)setLoadingMode:(BOOL)mode
{
  if (mode == loadingMode)
    return;
  
  loadingMode = mode;
  
  if (loadingMode)
  {
    if (!_activityIndicatorView)
    {
      _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    [self addSubview:_activityIndicatorView];
    [_activityIndicatorView startAnimating];
  }
  else
  {
    [_activityIndicatorView stopAnimating];
    [_activityIndicatorView removeFromSuperview];
  }
}

- (void)setContentInsets:(UIEdgeInsets)value
{
  if (UIEdgeInsetsEqualToEdgeInsets(value, contentInsets))
    return;
  contentInsets = value;
  [self setNeedsLayout];
}

- (NSString *)title {
  NSIndexSet *selected = selectedTitleFragments ?: [NSIndexSet indexSetWithIndex:titleFragments.count - 1];
  NSMutableString *result = [[NSMutableString alloc] init];
  [self.titleFragments enumerateObjectsAtIndexes:selected options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj isKindOfClass:NSString.class]) {
      [result appendFormat:@"%@ ", obj];
    } else if ([obj isKindOfClass:UILabel.class]) {
      [result appendFormat:@"%@ ", [(UILabel *)obj text]];
    }
  }];
  return [result copy];
}

#pragma mark - View Methods

- (void)layoutSubviews
{
  CGRect bounds = self.bounds;
  
  self.backgroundButton.frame = bounds;
  _activityIndicatorView.center = CGPointMake(20, bounds.size.height / 2);
  
  bounds = UIEdgeInsetsInsetRect(bounds, self.contentInsets);
  
  CGRect labelFrame = CGRectZero;
  for (UIView *view in _currentViews)
  {
    [view sizeToFit];
    labelFrame.size.width += view.bounds.size.width + gapBetweenFragments;
  }
  // Account for large frames
  if (labelFrame.size.width > bounds.size.width) {
    labelFrame.size.width = bounds.size.width;
  }
  labelFrame.size.width -= gapBetweenFragments;
  labelFrame.size.height = bounds.size.height;
  labelFrame.origin = CGPointMake( self.contentInsets.left + (bounds.size.width - labelFrame.size.width) / 2.0, self.contentInsets.top + (bounds.size.height - labelFrame.size.height) / 2.0);
  
  // Selected, current views layout
  CGRect viewFrame, lastViewFrame = labelFrame;
  lastViewFrame.size = CGSizeZero;
  for (UIView *view in _currentViews) {
    viewFrame = view.frame;
    viewFrame.origin = CGPointMake(CGRectGetMaxX(lastViewFrame), labelFrame.origin.y + (labelFrame.size.height - viewFrame.size.height) / 2.0);
    lastViewFrame = CGRectIntegral(viewFrame);
    // Early exit if already using all the real estate
    if (CGRectGetMaxX(lastViewFrame) > CGRectGetMaxX(bounds)) {
      lastViewFrame.size.width = CGRectGetMaxX(bounds) - lastViewFrame.origin.x;
      view.frame = lastViewFrame;
      lastViewFrame.origin.x += gapBetweenFragments;
      return;
    }
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
    
    maxSegmentWidth -= lastViewFrame.size.width + gapBetweenFragments;
    if (maxSegmentWidth <= 0)
      break;
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
  ASSERT(0 && "Should not be called, use titleFragments instead");
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
  ASSERT(0 && "Should not be called, use titleFragments instead");
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
  return YES;
}

- (UIAccessibilityTraits)accessibilityTraits {
  return UIAccessibilityTraitButton;
}

- (NSString *)accessibilityLabel {
  if (!_currentViews)
    [self _setupTitle];
  NSMutableString *label = [[NSMutableString alloc] init];
  NSString *sep = nil;
  for (UIView *view in _currentViews) {
    if (sep)
      [label appendString:sep];
    if ([view respondsToSelector:@selector(text)]) {
      [label appendString:[(UILabel *)view text]];
      sep = @", ";
    }
  }
  return [label copy];
}

#pragma mark - Private Methods

- (void)_setupTitle
{
  if (!titleFragments.count)
    return;
  
  NSIndexSet *selected = selectedTitleFragments ? selectedTitleFragments : [NSIndexSet indexSetWithIndex:titleFragments.count - 1];
  
  [_preViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  _preViews = ([selected firstIndex] > 0) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [selected firstIndex])] isPrimary:NO] : nil;
  
  [_postViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  _postViews = ([selected lastIndex] + 1 < titleFragments.count) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([selected lastIndex] + 1, titleFragments.count - [selected lastIndex] - 1) ] isPrimary:NO] : nil;
  
  [_currentViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  _currentViews = selected.count ? [self _setupViewArrayFromTitleFragmentIndexes:selected isPrimary:YES] : nil;
}

- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes isPrimary:(BOOL)isPrimary
{
  if (fragmentIndexes.count == 0)
    return nil;
  
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:fragmentIndexes.count];
  [titleFragments enumerateObjectsAtIndexes:fragmentIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj isKindOfClass:NSString.class])
    {
      UILabel *label = [[UILabel alloc] init];
      label.lineBreakMode = NSLineBreakByTruncatingMiddle;
      label.backgroundColor = UIColor.clearColor;
      
      label.textColor = isPrimary ? self.selectedTitleFragmentsTint : self.secondaryTitleFragmentsTint;
      label.font = isPrimary ? self.selectedFragmentFont : self.secondaryFragmentFont;
      
      label.shadowColor = [UIColor colorWithWhite:0.1 alpha:1];
      
      label.text = (NSString *)obj;
      label.isAccessibilityElement = NO;
      [result addObject:label];
    }
    else if ([obj isKindOfClass:UIImage.class])
    {
      [result addObject:[[UIImageView alloc] initWithImage:(UIImage *)obj]];
    }
    else if ([obj isKindOfClass:UIView.class])
    {
      [(UIView *)obj setIsAccessibilityElement:NO];
      [result addObject:obj];
    }
    else return;
    [self addSubview:[result lastObject]];
  }];
  return result;
}

@end
