//
//  ECCodeView.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeViewBase.h"
#import "ECPopoverController.h"

@class ECCodeView;

@protocol ECCodeViewDelegate <ECCodeViewBaseDelegate>

@optional

/// This function is called by an \c ECCodeView when the user require a complition
/// of a word or partial filter word in the text.
- (void)codeView:(ECCodeView *)codeView completionRequestAtTextLocation:(NSUInteger)location withFilterWord:(NSString *)filter;

@end


@interface ECCodeView : ECCodeViewBase <UIKeyInput, UITextInputTraits, UITextInput>

@property (nonatomic, assign) id<ECCodeViewDelegate> delegate;

#pragma mark Managing the Navigator

@property (nonatomic) CGFloat navigatorWidth;

@property (nonatomic, retain) UIColor *navigatorBackgroundColor;

@property (nonatomic, getter = isNavigatorVisible) BOOL navigatorVisible;

#pragma mark Detail Looking glass

//@property (nonatomic, readonly) ECPopoverController *detailPopover;

#pragma mark UITextInput Properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@end
