//
//  TabBar.m
//  ACUI
//
//  Created by Nicola Peduzzi on 22/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TabBar.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "NSTimer+BlockTimer.h"
#import "UIView+ReuseIdentifier.h"

typedef void (^ScrollViewBlock)(UIScrollView *scrollView);

// Custom scroll view to manage it's layout with a block
@interface TabBarScrollView : UIScrollView
@property (nonatomic, copy) ScrollViewBlock customLayoutSubviews;
@end

@interface TabBar () {
@private
  NSMutableArray *tabControls;
  NSMutableArray *reusableTabControls;
  TabBarScrollView *tabControlsContainerView;
  
  CAGradientLayer *leftFadeLayer;
  CAGradientLayer *rightFadeLayer;
  
  UIView *additionalControlsContainerView;
  
  UIControl *movedTab;
  CGPoint movedTabOffsetFromCenter;
  NSUInteger movedTabIndex, movedTabDestinationIndex;
  NSTimer *movedTabScrollTimer;
  
  struct {
    unsigned int hasWillSelectTabControlAtIndex :1;
    unsigned int hasDidSelectTabControlAtIndex : 1;
    unsigned int hasWillAddTabAtIndex :1;
    unsigned int hasDidAddTabAtIndexAnimated : 1;
    unsigned int hasWillRemoveTabControlAtIndex : 1;
    unsigned int hasDidRemoveTabControlAtIndex : 1;
    unsigned int hasWillMoveTabControlAtIndex : 1;
    unsigned int hasDidMoveTabControlFromIndexToIndex : 1;
  } delegateFlags;
}

@property (nonatomic, weak) UIControl *selectedTabControl;
- (void)_setSelectedTabControl:(UIControl *)tabControl;
- (void)_setSelectedTabControl:(UIControl *)tabControl animated:(BOOL)animated;
- (void)_removeTabControl:(UIControl *)tabControl animated:(BOOL)animated;
- (void)_moveTabAction:(UILongPressGestureRecognizer *)recognizer;
// Action attached to close button that willk remove the tab button
- (void)_closeTabAction:(id)sender;

- (UIControl *)_dequeueReusableTabControlWithIdentifier:(NSString *)reuseIdentifier;
- (UIControl *)_controlForTabWithTitle:(NSString *)title atIndex:(NSUInteger)tabIndex;

@end


@implementation TabBar

#pragma mark - Properties

@synthesize delegate;
@synthesize longPressGestureRecognizer;
@synthesize tabControlSize, tabControlInsets;
@synthesize additionalControls, additionalControlSize, additionalControlInsets;
@synthesize selectedTabControl;
@synthesize tabControls;

- (void)setDelegate:(id<TabBarDelegate>)aDelegate
{
  delegate = aDelegate;
  
  delegateFlags.hasWillSelectTabControlAtIndex = [delegate respondsToSelector:@selector(tabBar:willSelectTabControl:atIndex:)];
  delegateFlags.hasDidSelectTabControlAtIndex = [delegate respondsToSelector:@selector(tabBar:didSelectTabControl:atIndex:)];
  delegateFlags.hasWillAddTabAtIndex = [delegate respondsToSelector:@selector(tabBar:willAddTabAtIndex:)];
  delegateFlags.hasDidAddTabAtIndexAnimated = [delegate respondsToSelector:@selector(tabBar:didAddTabAtIndex:animated:)];
  delegateFlags.hasWillRemoveTabControlAtIndex = [delegate respondsToSelector:@selector(tabBar:willRemoveTabControl:atIndex:)];
  delegateFlags.hasDidRemoveTabControlAtIndex = [delegate respondsToSelector:@selector(tabBar:didRemoveTabControl:atIndex:)];    
  delegateFlags.hasWillMoveTabControlAtIndex = [delegate respondsToSelector:@selector(tabBar:willMoveTabControl:atIndex:)];
  delegateFlags.hasDidMoveTabControlFromIndexToIndex = [delegate respondsToSelector:@selector(tabBar:didMoveTabControl:fromIndex:toIndex:)];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  [super setBackgroundColor:backgroundColor];
  
  leftFadeLayer.colors = @[(__bridge id)(backgroundColor.CGColor),
                          (__bridge id)([backgroundColor colorWithAlphaComponent:0].CGColor)];
  rightFadeLayer.colors = @[(__bridge id)([backgroundColor colorWithAlphaComponent:0].CGColor),
                           (__bridge id)(backgroundColor.CGColor)];
}

- (void)setTabControlInsets:(UIEdgeInsets)insets
{
  if (UIEdgeInsetsEqualToEdgeInsets(insets, tabControlInsets))
    return;
  
  tabControlInsets = insets;
  [tabControlsContainerView setNeedsLayout];
}

- (void)setAdditionalControls:(NSArray *)array
{
  additionalControls = array;
  
  if (!additionalControls || additionalControls.count == 0)
  {
    [additionalControlsContainerView removeFromSuperview];
    additionalControlsContainerView = nil;
    return;
  }
  
  if (!additionalControlsContainerView)
  {
    additionalControlsContainerView = [[UIView alloc] init];
    additionalControlsContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    additionalControlsContainerView.backgroundColor = UIColor.clearColor;
    [self addSubview:additionalControlsContainerView];
  }
  else
  {
    [additionalControlsContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  }
  
  CGRect bounds = self.bounds;
  CGRect viewFrame;
  CGPoint defaultOrigin = CGPointZero;
  CGSize defaultSize = CGSizeMake(additionalControlSize.width, additionalControlSize.height ? additionalControlSize.height : bounds.size.height);
  for (UIView *view in additionalControls)
  {
    viewFrame = view.frame;
    if (CGRectIsEmpty(viewFrame))
      viewFrame.size = defaultSize;
    
    viewFrame.origin = defaultOrigin;
    defaultOrigin.x += viewFrame.size.width;
    
    view.frame = UIEdgeInsetsInsetRect(viewFrame, additionalControlInsets);
    
    [additionalControlsContainerView addSubview:view];
  }
  
  tabControlsContainerView.frame = CGRectMake(0, 0, bounds.size.width - defaultOrigin.x, bounds.size.height);
  additionalControlsContainerView.frame = CGRectMake(bounds.size.width - defaultOrigin.x, 0, defaultOrigin.x, bounds.size.height);
}

#pragma mark - View Lifecicle

static void updateFadeViews(TabBar *self)
{    
  // Update left fade layer
  if (!self->leftFadeLayer)
  {
    self->leftFadeLayer = [CAGradientLayer layer];
    self->leftFadeLayer.anchorPoint = CGPointMake(0, 0);
    self->leftFadeLayer.bounds = CGRectMake(0, 0, 20, self.frame.size.height);
    self->leftFadeLayer.actions = @{ @"position": NSNull.null };
    self->leftFadeLayer.startPoint = CGPointMake(0, .5);
    self->leftFadeLayer.endPoint = CGPointMake(1, .5);
    self->leftFadeLayer.opacity = 0;
    [self.layer addSublayer:self->leftFadeLayer];
  }
  
  // Update right fade layer
  if (!self->rightFadeLayer)
  {
    self->rightFadeLayer = [CAGradientLayer layer];
    self->rightFadeLayer.anchorPoint = CGPointMake(0, 0);
    self->rightFadeLayer.bounds = CGRectMake(0, 0, 20, self.frame.size.height);
    self->rightFadeLayer.actions = @{ @"position": NSNull.null };
    self->rightFadeLayer.startPoint = CGPointMake(0, .5);
    self->rightFadeLayer.endPoint = CGPointMake(1, .5);
    self->rightFadeLayer.opacity = 0;
    [self.layer addSublayer:self->rightFadeLayer];
  }
}

static void preinit(TabBar *self)
{
  self->tabControlSize = CGSizeMake(300, 0);
  self->tabControlInsets = UIEdgeInsetsMake(7, 3, 7, 3);
  self->additionalControlSize = CGSizeMake(41, 0);
  self->additionalControlInsets = UIEdgeInsetsMake(7, 0, 7, 7);
}

static void init(TabBar *self)
{
  // Tab container
  self->tabControlsContainerView = [[TabBarScrollView alloc] init];
  self->tabControlsContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self->tabControlsContainerView.backgroundColor = UIColor.clearColor;
  self->tabControlsContainerView.contentInset = UIEdgeInsetsMake(0, 4, 0, 4);
  self->tabControlsContainerView.alwaysBounceHorizontal = YES;
  [self->tabControlsContainerView setShowsVerticalScrollIndicator:NO];
  [self->tabControlsContainerView setShowsHorizontalScrollIndicator:NO];
  __weak TabBar *this = self;
  self->tabControlsContainerView.customLayoutSubviews = ^(UIScrollView *scrollView) {
    TabBar *strongSelf = this;
    if (!strongSelf) {
      return;
    }
    
    CGRect bounds = scrollView.bounds;
    
    // TODO: remove non visible controls
    
    // Determine button's size
    CGRect buttonFrame = (CGRect) { CGPointZero, strongSelf->tabControlSize };
    if (buttonFrame.size.height == 0)
      buttonFrame.size.height = bounds.size.height;
    
    // Layout tab buttons
    NSUInteger buttonIndex = 0;
    for (UIControl *button in strongSelf->tabControls)
    {
      if (strongSelf->movedTab != nil
          && buttonIndex == strongSelf->movedTabDestinationIndex 
          && strongSelf->movedTabIndex > strongSelf->movedTabDestinationIndex)
      {
        buttonFrame.origin.x += buttonFrame.size.width;
      }
      
      if (button != strongSelf->movedTab)
      {
        button.frame = UIEdgeInsetsInsetRect(buttonFrame, strongSelf->tabControlInsets);
        buttonFrame.origin.x += buttonFrame.size.width;
      }
      
      if (strongSelf->movedTab != nil
          && buttonIndex == strongSelf->movedTabDestinationIndex 
          && strongSelf->movedTabIndex <= strongSelf->movedTabDestinationIndex)
      {
        buttonFrame.origin.x += buttonFrame.size.width;
      }
      
      ++buttonIndex;
    }
    
    // Show left fading layer
    if (bounds.origin.x > 0)
    {
      strongSelf->leftFadeLayer.frame = (CGRect){ 
        CGPointZero, 
        CGSizeMake(20, bounds.size.height)
      };
      strongSelf->leftFadeLayer.opacity = 1;
    }
    else
    {
      strongSelf->leftFadeLayer.opacity = 0;
    }
    
    // Show right fading layer
    if (CGRectGetMaxX(bounds) < scrollView.contentSize.width)
    {
      strongSelf->rightFadeLayer.frame = (CGRect){ 
        CGPointMake(bounds.size.width - strongSelf->rightFadeLayer.bounds.size.width, 0),
        CGSizeMake(20, bounds.size.height)
      };
      strongSelf->rightFadeLayer.opacity = 1;
    }
    else
    {
      strongSelf->rightFadeLayer.opacity = 0;
    }
  };
  [self addSubview:self->tabControlsContainerView];
  
  // Move recognizer
  self->longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_moveTabAction:)];
  [self->tabControlsContainerView addGestureRecognizer:self->longPressGestureRecognizer];
  
  // Create fade views
  updateFadeViews(self);
  
  [self setNeedsLayout];
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

- (id)initWithCoder:(NSCoder *)coder
{
  preinit(self);
  if ((self = [super initWithCoder:coder]))
  {
    init(self);       
  }
  return self;
}

#pragma mark - Managing Tabs

- (NSUInteger)tabsCount {
  return tabControls.count;
}

- (NSUInteger)selectedTabIndex
{
  return selectedTabControl ? [tabControls indexOfObject:selectedTabControl] : NSNotFound;
}

- (void)setSelectedTabIndex:(NSUInteger)index
{
  [self setSelectedTabIndex:index animated:NO];
}

- (void)setSelectedTabIndex:(NSUInteger)index animated:(BOOL)animated
{
  if (index == NSNotFound)
    [self _setSelectedTabControl:nil animated:animated];
  
  ASSERT(index < tabControls.count);
  UIControl *tabControl = tabControls[index];
  [self _setSelectedTabControl:tabControl animated:animated];
}

- (void)addTabWithTitle:(NSString *)title animated:(BOOL)animated
{
  NSUInteger newTabControlIndex = tabControls.count;
  if (delegateFlags.hasWillAddTabAtIndex
      && ![delegate tabBar:self willAddTabAtIndex:newTabControlIndex])
    return;
  
  if (!tabControls)
    tabControls = [NSMutableArray array];
  
  // Creating new tab control
  [self willChangeValueForKey:@"tabsCount"];
  UIControl *newTabControl = [self _controlForTabWithTitle:(title ? title : @"") atIndex:newTabControlIndex];
  [tabControls addObject:newTabControl];
  [self didChangeValueForKey:@"tabsCount"];
  
  // Assigning default tab control selection action
  [newTabControl addTarget:self action:@selector(_setSelectedTabControl:) forControlEvents:UIControlEventTouchUpInside];
  
  // Position and size new tab control
  //    CGRect tabControlFrame = (CGRect) { CGPointMake(tabControlSize.width * newTabControlIndex, 0), tabControlSize };
  //    if (tabControlFrame.size.height == 0)
  //        tabControlFrame.size.height = tabControlsContainerView.bounds.size.height;
  //    newTabControl.frame = UIEdgeInsetsInsetRect(tabControlFrame, tabControlInsets);
  
  // Resize content
  // TODO: check with height = 0
  tabControlsContainerView.contentSize = CGSizeMake(tabControlSize.width * (newTabControlIndex + 1), 1);
  
  [tabControlsContainerView addSubview:newTabControl];
  newTabControl.alpha = 0;
  [UIView animateWithDuration:animated ? .20 : 0 animations:^(void) {
    newTabControl.alpha = 1;
  } completion:^(BOOL finished) {
    if (delegateFlags.hasDidAddTabAtIndexAnimated)
      [delegate tabBar:self didAddTabAtIndex:newTabControlIndex animated:animated];
  }];
}

- (void)removeTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated
{
  ASSERT(tabIndex < tabControls.count);
  UIControl *tabControl = tabControls[tabIndex];
  [self _removeTabControl:tabControl animated:animated];
}

- (void)moveTabAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated
{
  ASSERT(fromIndex < tabControls.count);
  ASSERT(toIndex < tabControls.count);
  
  id obj = tabControls[fromIndex];
  [tabControls removeObjectAtIndex:fromIndex];
  [tabControls insertObject:obj atIndex:toIndex];
  
  if (animated)
  {
    [UIView animateWithDuration:0.2 animations:^{
      [tabControlsContainerView layoutSubviews];
    }];
  }
  else
  {
    [tabControlsContainerView setNeedsLayout];
  }
}

- (void)setTitle:(NSString *)title forTabAtIndex:(NSUInteger)tabIndex
{
  ASSERT(tabIndex < tabControls.count);
  
  UIButton *tabButton = (UIButton *)tabControls[tabIndex];
  [tabButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark -

- (void)_moveTabAction:(UILongPressGestureRecognizer *)recognizer
{
  CGPoint locationInView = [recognizer locationInView:tabControlsContainerView];
  switch (recognizer.state)
  {
    case UIGestureRecognizerStateBegan:
    {
      // Get tab to move and forward to delegate to ask for permission
      movedTabIndex = (NSUInteger)(locationInView.x / tabControlSize.width);
      movedTabDestinationIndex = movedTabIndex;
      movedTab = tabControls[movedTabIndex];
      if (delegateFlags.hasWillMoveTabControlAtIndex
          && ![delegate tabBar:self willMoveTabControl:movedTab atIndex:movedTabIndex])
      {
        movedTab = nil;
        return;
      }
      
      // Record center offset and animate motion beginning
      movedTabOffsetFromCenter = CGPointMake(movedTab.center.x - locationInView.x, 0);
      [tabControlsContainerView bringSubviewToFront:movedTab];
      [UIView animateWithDuration:0.2 animations:^(void) {
        [movedTab setTransform:CGAffineTransformMakeScale(1.1, 1.1)];
        [movedTab setAlpha:0.75];
      }];
      
      break;
    }
      
    case UIGestureRecognizerStateChanged:
      if (movedTab)
      {
        // Move tab horizontaly
        CGPoint movedTabCenter = movedTab.center;
        movedTabCenter.x = locationInView.x + movedTabOffsetFromCenter.x;
        movedTab.center = movedTabCenter;
        
        // Select final destination
        movedTabDestinationIndex = (NSUInteger)(locationInView.x / tabControlSize.width);
        if (movedTabDestinationIndex >= tabControls.count)
          movedTabDestinationIndex = tabControls.count - 1;
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
          [tabControlsContainerView layoutSubviews];                    
        } completion:nil];
        
        // Calculate scrolling offset
        CGPoint contentOffset = tabControlsContainerView.contentOffset;
        CGFloat scrollLocationInView = locationInView.x - contentOffset.x;
        CGFloat scrollingOffset = 0;
        if (scrollLocationInView < 60)
          scrollingOffset = -(scrollLocationInView);
        else if (scrollLocationInView > tabControlsContainerView.frame.size.width - 60)
          scrollingOffset = scrollLocationInView - (tabControlsContainerView.frame.size.width - 60);
        
        // Manual scrolling
        [movedTabScrollTimer invalidate];
        if (scrollingOffset != 0)
        {
          __weak TabBar *this = self;
          movedTabScrollTimer = [NSTimer scheduledTimerWithTimeInterval:1./100. usingBlock:^(NSTimer *timer) {
            TabBar *strongSelf = this;
            if (!strongSelf) {
              return;
            }
            
            CGFloat contentOffsetX = strongSelf->tabControlsContainerView.contentOffset.x;
            if ((scrollingOffset < 0 && contentOffsetX <= 0)
                || (scrollingOffset > 0 && contentOffsetX >= (strongSelf->tabControlsContainerView.contentSize.width - strongSelf->tabControlsContainerView.bounds.size.width)))
            {
              [strongSelf->movedTabScrollTimer invalidate];
              strongSelf->movedTabScrollTimer = nil;
            }
            else
            {
              CGFloat delta = roundf(scrollingOffset / 5);
              contentOffsetX += delta;
              
              CGPoint center = strongSelf->movedTab.center;
              center.x += delta;
              strongSelf->movedTab.center = center;
              
              [strongSelf->tabControlsContainerView scrollRectToVisible:CGRectMake(contentOffsetX, 0, strongSelf->tabControlsContainerView.bounds.size.width, 1) animated:NO];
            }
          } repeats:YES];
        }
        else
          movedTabScrollTimer = nil;
      }
      break;
      
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled:
      if (movedTab)
      {
        // Stop scrolling timer
        [movedTabScrollTimer invalidate];
        movedTabScrollTimer = nil;
        
        // Apply movement
        if (movedTabIndex != movedTabDestinationIndex)
        {
          [tabControls removeObjectAtIndex:movedTabIndex];
          [tabControls insertObject:movedTab atIndex:movedTabDestinationIndex];
        }
        
        // Animate to position
        UIControl *movedTabControl = movedTab;
        movedTab = nil;
        [UIView animateWithDuration:0.2 animations:^(void) {
          [movedTabControl setTransform:CGAffineTransformIdentity];
          [movedTabControl setAlpha:1.0];
          [tabControlsContainerView layoutSubviews];
        } completion:^(BOOL finished) {
          if (delegateFlags.hasDidMoveTabControlFromIndexToIndex)
            [delegate tabBar:self didMoveTabControl:movedTabControl fromIndex:movedTabIndex toIndex:movedTabDestinationIndex];
        }];
      }
      break;
      
    default:
      break;
  }
}

#pragma mark - Private methods

- (void)_setSelectedTabControl:(UIControl *)tabControl
{
  [self _setSelectedTabControl:tabControl animated:NO];
}

- (void)_setSelectedTabControl:(UIControl *)tabControl animated:(BOOL)animated
{
  // Deselection
  if (tabControl == nil)
  {
    [selectedTabControl setSelected:NO];
    selectedTabControl = nil;
    return;
  }
  
  // Only scroll if already selected
  if (tabControl == selectedTabControl)
  {
    CGRect selectedTabFrame = selectedTabControl.frame;
    selectedTabFrame.origin.x -= tabControlInsets.left;
    selectedTabFrame.size.width += tabControlInsets.left + tabControlInsets.right;
    selectedTabFrame.origin.y = 0;
    selectedTabFrame.size.height = 1;
    [tabControlsContainerView scrollRectToVisible:selectedTabFrame animated:animated];
    return;
  }
  
  // Retrieve index
  NSUInteger tabIndex = [tabControls indexOfObject:tabControl];
  if (tabIndex == NSNotFound)
    return;
  
  // Ask selection permission to delegate
  if (delegateFlags.hasWillSelectTabControlAtIndex
      && ![delegate tabBar:self willSelectTabControl:tabControl atIndex:tabIndex])
    return;
  
  [self willChangeValueForKey:@"selectedTabIndex"];
  
  // Change selection
  [selectedTabControl setSelected:NO];
  selectedTabControl = tabControl; // TODO:!!! make this weak
  [selectedTabControl setSelected:YES];
  
  [self didChangeValueForKey:@"selectedTabIndex"];
  
  // Scroll to fully show tab
  CGRect selectedTabFrame = selectedTabControl.frame;
  selectedTabFrame.origin.x -= tabControlInsets.left;
  selectedTabFrame.size.width += tabControlInsets.left + tabControlInsets.right;
  selectedTabFrame.origin.y = 0;
  selectedTabFrame.size.height = 1;
  [UIView animateWithDuration:animated ? 0.25 : 0 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
    [tabControlsContainerView scrollRectToVisible:selectedTabFrame animated:NO];
  } completion:^(BOOL finished) {
    if (delegateFlags.hasDidSelectTabControlAtIndex)
      [delegate tabBar:self didSelectTabControl:tabControl atIndex:tabIndex];
  }];
}

- (void)_removeTabControl:(UIControl *)tabControl animated:(BOOL)animated
{
  ASSERT(tabControl != nil);
  
  NSUInteger tabIndex = [tabControls indexOfObject:tabControl];
  ASSERT(tabIndex != NSNotFound);
  
  if (delegateFlags.hasWillRemoveTabControlAtIndex
      && ![delegate tabBar:self willRemoveTabControl:tabControl atIndex:tabIndex])
    return;
  
  [self willChangeValueForKey:@"tabsCount"];
  [tabControls removeObjectAtIndex:tabIndex];
  [self didChangeValueForKey:@"tabsCount"];
  
  if (tabControl.reuseIdentifier)
  {
    if (!reusableTabControls)
      reusableTabControls = [NSMutableArray array];
    [reusableTabControls addObject:tabControl];
  }
  
  if (animated)
  {
    tabControl.layer.shouldRasterize = YES;
    [UIView animateWithDuration:.10 animations:^(void) {
      tabControl.alpha = 0;
    } completion:^(BOOL outerFinished) {
      tabControl.layer.shouldRasterize = NO;
      [UIView animateWithDuration:.15 animations:^(void) {
        [tabControlsContainerView layoutSubviews];
      } completion:^(BOOL innerFinished) {
        tabControl.alpha = 1;
        [tabControl removeFromSuperview];
        tabControlsContainerView.contentSize = CGSizeMake(tabControlSize.width * tabControls.count, 1);
        
        if (delegateFlags.hasDidRemoveTabControlAtIndex)
          [delegate tabBar:self didRemoveTabControl:tabControl atIndex:tabIndex];
      }];
    }];
  }
  else
  {
    [tabControl removeFromSuperview];
    
    tabControlsContainerView.contentSize = CGSizeMake(tabControlSize.width * tabControls.count, 1);
    
    if (delegateFlags.hasDidRemoveTabControlAtIndex)
      [delegate tabBar:self didRemoveTabControl:tabControl atIndex:tabIndex];
  }
}

- (void)_closeTabAction:(id)sender
{
  [self _removeTabControl:(UIControl *)[sender superview] animated:YES];
}

- (UIControl *)_dequeueReusableTabControlWithIdentifier:(NSString *)reuseIdentifier
{
  ASSERT(reuseIdentifier != nil);
  UIControl *result = nil;
  for (UIControl *control in reusableTabControls)
  {
    if ([reuseIdentifier isEqualToString:control.reuseIdentifier])
    {
      result = control;
      break;
    }
  }
  
  if (result)
    [reusableTabControls removeObject:result];
  
  return result;
}

- (UIControl *)_controlForTabWithTitle:(NSString *)title atIndex:(NSUInteger)tabIndex
{
  static NSString *tabButtonReusableIdentifier = @"TabBarButton";
  
  TabBarButton *tabButton = (TabBarButton *)[self _dequeueReusableTabControlWithIdentifier:tabButtonReusableIdentifier];
  if (tabButton == nil) {
    tabButton = [TabBarButton buttonWithType:UIButtonTypeCustom];
    tabButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    tabButton.frame = CGRectMake(0, 0, 100, 44);
    
    tabButton.reuseIdentifier = tabButtonReusableIdentifier;
    
    TabBarButtonCloseButton *tabCloseButton = [TabBarButtonCloseButton buttonWithType:UIButtonTypeCustom];
    [tabCloseButton addTarget:self action:@selector(_closeTabAction:) forControlEvents:UIControlEventTouchUpInside];
    tabCloseButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    tabCloseButton.frame = CGRectMake(0, 0, 44, 44);
    
    // RAC
    // Adjust title inset and close button when the tab is selected
    @weakify(tabButton);
    [[tabButton rac_signalForKeyPath:@keypath(tabButton, selected) observer:tabButton] subscribeNext:^(NSNumber *selected) {
      @strongify(tabButton);
      if ([selected boolValue]) {
        [tabButton addSubview:tabCloseButton];
        [tabButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 38, 0, 3)];
      } else {
        [tabCloseButton removeFromSuperview];
        [tabButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 3, 0, 3)];
      }
    }];
  }
  
  [tabButton setTitle:title forState:UIControlStateNormal];
  
  return tabButton;
}

@end


@implementation TabBarButton
@end


@implementation TabBarButtonCloseButton
@end


@implementation TabBarScrollView

@synthesize customLayoutSubviews;

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  customLayoutSubviews(self);
}

@end
