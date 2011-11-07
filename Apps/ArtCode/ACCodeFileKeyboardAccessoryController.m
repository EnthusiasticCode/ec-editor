//
//  ACCodeFileKeyboardAccessoryController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryController.h"
#import "ACCodeFileController.h"
#import <ECUIKit/ECCodeView.h>

#define ACCESSORY_HEIGHT 45
#define ACCESSORY_FLIP_Y_POSITION 180
#define KEYBOARD_DOCKED_MINIMUM_HEIGHT 264

@interface ACCodeFileKeyboardAccessoryController ()

- (void)_keyboardWillChangeFrame:(NSNotification *)notification;
- (void)_keyboardDidChangeFrame:(NSNotification *)notification;

- (void)_itemAction:(id)sender;

@end


@implementation ACCodeFileKeyboardAccessoryController

#pragma mark - Properties

@synthesize keyboardAccessoryView = _keyboardAccessoryView;
@synthesize targetCodeFileController;

- (ACCodeFileKeyboardAccessoryView *)keyboardAccessoryView
{
    if (!_keyboardAccessoryView)
    {
        _keyboardAccessoryView = [ACCodeFileKeyboardAccessoryView new];
        _keyboardAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _keyboardAccessoryView.dockedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundDocked"]];
        UIImageView *splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitLeftTop"]];
        splitBackgroundView.contentMode = UIViewContentModeTopLeft;
        _keyboardAccessoryView.splitLeftBackgroundView = splitBackgroundView;
        splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitRightTop"]];
        splitBackgroundView.contentMode = UIViewContentModeTopRight;
        _keyboardAccessoryView.splitRightBackgroundView = splitBackgroundView;
        _keyboardAccessoryView.splitBackgroundViewInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
        
        // Layou
        _keyboardAccessoryView.itemBackgroundImage = [[UIImage imageNamed:@"accessoryView_itemBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 12, 0, 12)];
        
        [_keyboardAccessoryView setItemDefaultWidth:59 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionPortrait];
        [_keyboardAccessoryView setItemDefaultWidth:81 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionLandscape];
        [_keyboardAccessoryView setItemDefaultWidth:36 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionFloating]; // 44
        
        [_keyboardAccessoryView setContentInsets:UIEdgeInsetsMake(3, 0, 2, 0) forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionPortrait];
        [_keyboardAccessoryView setItemInsets:UIEdgeInsetsMake(0, 3, 0, 3) forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionPortrait];
        
        [_keyboardAccessoryView setContentInsets:UIEdgeInsetsMake(3, 4, 2, 3) forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionLandscape];
        [_keyboardAccessoryView setItemInsets:UIEdgeInsetsMake(0, 0, 0, 8) forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionLandscape];
        
        [_keyboardAccessoryView setContentInsets:UIEdgeInsetsMake(3, 10, 2, 7) forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionFloating];
        [_keyboardAccessoryView setItemInsets:UIEdgeInsetsMake(0, 0, 0, 3) forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionFloating];
        
        // Items
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:11];
        ACCodeFileKeyboardAccessoryItem *item;
        
        for (NSInteger i = 0; i < 11; ++i)
        {
            item = [[ACCodeFileKeyboardAccessoryItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", i] style:UIBarButtonItemStylePlain target:self action:@selector(_itemAction:)];
            item.tag = i;
            [items addObject:item];
            
            if (i == 0)
                [item setWidth:44 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionFloating];
            
            if (i % 2)
                [item setWidth:60 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionPortrait];
                
            if (i == 10)
            {
                [item setWidth:63 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionPortrait];
                [item setWidth:82 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionLandscape];
                [item setWidth:44 + 4 forAccessoryPosition:ACCodeFileKeyboardAccessoryPositionFloating];
            }
        }
        _keyboardAccessoryView.items = items;
    }
    return _keyboardAccessoryView;
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = self.keyboardAccessoryView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Controller's Methods

- (id)init
{
    if (!(self = [super init]))
        return nil;
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(_keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)_keyboardWillChangeFrame:(NSNotification *)notification
{
    // Hide keyboard before changing frame
    [_keyboardAccessoryView removeFromSuperview];
}

- (void)_keyboardDidChangeFrame:(NSNotification *)notification
{
#warning TODO NIK use self.targetCodeFileController.isEditing insead
    if (!self.targetCodeFileController.codeView.isFirstResponder)
        return;
    
    CGRect keyboardEndFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Only show accessory view if keyboard is visible
    if (!CGRectIntersectsRect(keyboardEndFrame, [[UIScreen mainScreen] bounds]))
        return;
    
    // Add to target view
    [self.targetCodeFileController.view addSubview:self.view];
    
    // Setup accessory view
    keyboardEndFrame = [self.targetCodeFileController.view convertRect:keyboardEndFrame fromView:nil];
    _keyboardAccessoryView.split = (keyboardEndFrame.size.height < KEYBOARD_DOCKED_MINIMUM_HEIGHT);
    _keyboardAccessoryView.flipped = (keyboardEndFrame.origin.y < ACCESSORY_FLIP_Y_POSITION);
    
    if (_keyboardAccessoryView.split && _keyboardAccessoryView.flipped)
    {
        keyboardEndFrame.origin.y += keyboardEndFrame.size.height;
    }
    else
    {
        keyboardEndFrame.origin.y -= ACCESSORY_HEIGHT;
    }
    keyboardEndFrame.size.height = ACCESSORY_HEIGHT;
    _keyboardAccessoryView.frame = keyboardEndFrame;
    
    _keyboardAccessoryView.alpha = 0;
    [_keyboardAccessoryView setNeedsLayout];
    [UIView animateWithDuration:0.25 animations:^{
        _keyboardAccessoryView.alpha = 1;
    }];
}

- (void)_itemAction:(id)sender
{
    
}

@end
