//
//  ECEditCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 07/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView.h"

@class ECEditCodeView;

@protocol ECEditCodeViewDelegate <NSObject>

/// Tells the delegate when the text in the given range has changed in the view's text property.
- (void)editCodeView:(ECEditCodeView *)view textChangedInRange:(UITextRange *)range;

@end


@interface ECEditCodeView : ECCodeView <UIKeyInput, UITextInputTraits, UITextInput>

#pragma mark Handling Code View Behaviours

@property (nonatomic, assign) id <ECEditCodeViewDelegate> delegate;

/// Provide a public selector to internally manage a focus gesture. The given recognizer will be deactivated on focus and reactivated when the view resign as first responder.
- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer;

#pragma mark UITextInput properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@end
