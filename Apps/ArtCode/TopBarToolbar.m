//
//  TopBarToolbar.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"

#define DEFAULT_BUTTON_WIDTH 48

static const void *editItemContext;

@interface TopBarToolbar ()

- (void)_setupButton:(UIButton *)button withBarButtonItem:(UIBarButtonItem *)item;

@end


@implementation TopBarToolbar

#pragma mark - Properties

@synthesize backButton, forwardButton;
@synthesize titleControl;
@synthesize editItem, toolItems;

@synthesize backgroundImage, buttonsInsets, controlsGap;

- (UIButton *)backButton
{
    if (!backButton)
    {
        backButton = [UIButton new];
        [backButton setImage:[UIImage imageNamed:@"topBar_BackButton_Normal"] forState:UIControlStateNormal];
        [backButton setImage:[UIImage imageNamed:@"topBar_BackButton_Disabled"] forState:UIControlStateDisabled];
        backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    }
    return backButton;
}

- (UIButton *)forwardButton
{
    if (!forwardButton)
    {
        forwardButton = [UIButton new];
        [forwardButton setImage:[UIImage imageNamed:@"topBar_ForwardButton_Normal"] forState:UIControlStateNormal];
        [forwardButton setImage:[UIImage imageNamed:@"topBar_ForwardButton_Disabled"] forState:UIControlStateDisabled];
        forwardButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    }
    return forwardButton;
}

- (TopBarTitleControl *)titleControl
{
    if (!titleControl)
    {
        titleControl = [TopBarTitleControl new];
        titleControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return titleControl;
}

- (void)setEditItem:(UIBarButtonItem *)item
{
    if (item == editItem)
        return;
    
    if (editItem)
    {
        [editItem.customView removeFromSuperview];
        [editItem removeObserver:self forKeyPath:@"title" context:&editItemContext];
    }
    
    if ((editItem = item))
    {
        [editItem addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:&editItemContext];
        
        if (!editItem.customView)
            [self _setupButton:[TopBarEditButton new] withBarButtonItem:editItem];
        [self addSubview:editItem.customView];
    }
    
    [self layoutSubviews];
}

- (void)setToolItems:(NSArray *)items animated:(BOOL)animated
{
    if (items == toolItems)
        return;
    
    NSArray *oldItems = [toolItems copy];
    toolItems = [items copy];
    for (UIBarButtonItem *item in toolItems) {
        if (!item.customView)
            [self _setupButton:[TopBarToolButton new] withBarButtonItem:item];
        if (animated)
            item.customView.alpha = 0;
        [self addSubview:item.customView];
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.10 animations:^{
            // Layout title control
            [self layoutSubviews];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.10 animations:^{
                // Fade-out old items
                for (UIBarButtonItem *item in oldItems) {
                    item.customView.alpha = 0;
                }
                // Fade-in new ones
                for (UIBarButtonItem *item in toolItems) {
                    item.customView.alpha = 1;
                }
            } completion:^(BOOL finished) {
                for (UIBarButtonItem *item in oldItems) {
                    [item.customView removeFromSuperview];
                }
            }];
        }];
    }
    else
    {
        for (UIBarButtonItem *item in oldItems) {
            [item.customView removeFromSuperview];
        }
        [self setNeedsLayout];
    }
}

#pragma mark - Observing edit item

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &editItemContext && [self.editItem.customView isMemberOfClass:[TopBarEditButton class]])
    {
        if ([keyPath isEqualToString:@"title"])
            [(UIButton *)self.editItem.customView setTitle:[change objectForKey:NSKeyValueChangeNewKey] forState:UIControlStateNormal];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    self.editItem = nil;
}

#pragma mark - View lifecycle

static void init(TopBarToolbar *self)
{
    self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    self->buttonsInsets = UIEdgeInsetsMake(6, 7, 5, 7);
    self->controlsGap = 10;
    
    [self addSubview:self.backButton];
    [self addSubview:self.forwardButton];
    [self addSubview:self.titleControl];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    init(self);
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (!(self = [super initWithCoder:coder]))
        return nil;
    init(self);
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [self.backgroundImage drawInRect:rect];
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    
    CGRect leftButtonsFrame = UIEdgeInsetsInsetRect(bounds, buttonsInsets);
    CGRect rightButtonsFrame = leftButtonsFrame;
    leftButtonsFrame.size.width = DEFAULT_BUTTON_WIDTH;
    rightButtonsFrame.origin.x += rightButtonsFrame.size.width;
    
    self.backButton.frame = leftButtonsFrame;
    leftButtonsFrame.origin.x += DEFAULT_BUTTON_WIDTH + controlsGap;
    
    self.forwardButton.frame = leftButtonsFrame;
    leftButtonsFrame.origin.x += DEFAULT_BUTTON_WIDTH + controlsGap;
    
    if (self.editItem)
    {
        rightButtonsFrame.size.width = editItem.width ? editItem.width : DEFAULT_BUTTON_WIDTH;
        rightButtonsFrame.origin.x -= rightButtonsFrame.size.width;
        editItem.customView.frame = rightButtonsFrame;
        rightButtonsFrame.origin.x -= controlsGap;
    }
    
    for (UIBarButtonItem *item in toolItems)
    {
        rightButtonsFrame.size.width = item.width ? item.width : DEFAULT_BUTTON_WIDTH;
        rightButtonsFrame.origin.x -= rightButtonsFrame.size.width;
        item.customView.frame = rightButtonsFrame;
        rightButtonsFrame.origin.x -= controlsGap;
    }
    
    self.titleControl.frame = (CGRect){ CGPointMake(leftButtonsFrame.origin.x, 0), CGSizeMake(rightButtonsFrame.origin.x - leftButtonsFrame.origin.x, bounds.size.height) };
}

#pragma mark - Private methods

- (void)_setupButton:(UIButton *)button withBarButtonItem:(UIBarButtonItem *)item
{
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    [button setTitle:item.title forState:UIControlStateNormal];
    [button setImage:item.image forState:UIControlStateNormal];
    if (item.target && item.action)
        [button addTarget:item.target action:item.action forControlEvents:UIControlEventTouchUpInside];
    item.customView = button;
}

@end


@implementation TopBarToolButton

/// Method called by UIPopoverController if presenting from toolbar item.
- (UIView *)view 
{
    return self;
}

@end

@implementation TopBarEditButton
@end
