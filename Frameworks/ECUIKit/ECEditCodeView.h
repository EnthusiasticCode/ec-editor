//
//  ECEditCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 07/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView.h"

@interface ECEditCodeView : ECCodeView <UIKeyInput, UITextInputTraits, UITextInput>

#pragma mark UITextInput properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@end
