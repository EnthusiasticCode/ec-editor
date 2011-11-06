//
//  ACCodeFileInputAccessoryView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryView.h"

#define SPLIT_KEYBOARD_SEGMENT_WIDTH 256

@implementation ACCodeFileKeyboardAccessoryView

// TODO see http://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html#//apple_ref/doc/uid/TP40009542-CH12-SW1 for input clicks

@synthesize split, flipped;
@synthesize dockedBackgroundView, splitLeftBackgroundView, splitRightBackgroundView, splitBackgroundViewInsets;

- (void)setDockedBackgroundView:(UIView *)value
{
    if (value == dockedBackgroundView)
        return;
    [self willChangeValueForKey:@"dockedBackgroundView"];
    if (!self.isSplit)
    {
        [dockedBackgroundView removeFromSuperview];
        if (value)
            [self addSubview:value];
    }
    dockedBackgroundView = value;
    [self didChangeValueForKey:@"dockedBackgroundView"];
}

- (void)setSplit:(BOOL)value
{
    if (value == split)
        return;
    
    [self willChangeValueForKey:@"split"];
    split = value;
    if (split)
    {
        [dockedBackgroundView removeFromSuperview];
        [self addSubview:self.splitLeftBackgroundView];
        [self addSubview:self.splitRightBackgroundView];
    }
    else
    {
        [splitLeftBackgroundView removeFromSuperview];
        [splitRightBackgroundView removeFromSuperview];
        [self addSubview:self.dockedBackgroundView];
    }
    [self didChangeValueForKey:@"split"];
}

#pragma mark - View's Methods

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    if (self.isSplit && self.splitLeftBackgroundView)
    {
        if (self.isFlipped)
        {
            self.splitLeftBackgroundView.transform = self.splitRightBackgroundView.transform = CGAffineTransformMakeScale(1, -1);
        }
        else
        {
            self.splitLeftBackgroundView.transform = self.splitRightBackgroundView.transform = CGAffineTransformIdentity;
        }
        self.splitLeftBackgroundView.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, SPLIT_KEYBOARD_SEGMENT_WIDTH, bounds.size.height), self.splitBackgroundViewInsets);
        self.splitRightBackgroundView.frame = UIEdgeInsetsInsetRect(CGRectMake(bounds.size.width - SPLIT_KEYBOARD_SEGMENT_WIDTH, 0, SPLIT_KEYBOARD_SEGMENT_WIDTH, bounds.size.height), self.splitBackgroundViewInsets);
    }
    else if (self.dockedBackgroundView)
    {
        self.dockedBackgroundView.frame = bounds;
    }
}

@end
