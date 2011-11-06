//
//  ACCodeFileKeyboardAccessoryController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryController.h"
#import "ACCodeFileKeyboardAccessoryView.h"
#import "ACCodeFileController.h"
#import <ECUIKit/ECCodeView.h>

#define ACCESSORY_HEIGHT 45
#define ACCESSORY_FLIP_Y_POSITION 180
#define KEYBOARD_DOCKED_MINIMUM_HEIGHT 264

@interface ACCodeFileKeyboardAccessoryController ()

@property (nonatomic, readonly, strong) ACCodeFileKeyboardAccessoryView *_keyboardAccessoryView;

- (void)_keyboardWillChangeFrame:(NSNotification *)notification;
- (void)_keyboardDidChangeFrame:(NSNotification *)notification;

@end


@implementation ACCodeFileKeyboardAccessoryController

#pragma mark - Properties

@synthesize _keyboardAccessoryView;
@synthesize targetCodeFileController;

- (ACCodeFileKeyboardAccessoryView *)_keyboardAccessoryView
{
    if (!_keyboardAccessoryView)
    {
        _keyboardAccessoryView = [ACCodeFileKeyboardAccessoryView new];
        _keyboardAccessoryView.dockedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundDocked"]];
        UIImageView *splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitLeftTop"]];
        splitBackgroundView.contentMode = UIViewContentModeTopLeft;
        _keyboardAccessoryView.splitLeftBackgroundView = splitBackgroundView;
        splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitRightTop"]];
        splitBackgroundView.contentMode = UIViewContentModeTopRight;
        _keyboardAccessoryView.splitRightBackgroundView = splitBackgroundView;
        _keyboardAccessoryView.splitBackgroundViewInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
    }
    return _keyboardAccessoryView;
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = self._keyboardAccessoryView;
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

@end
