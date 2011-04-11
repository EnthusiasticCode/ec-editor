//
//  ECCodeView3.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ECCodeViewDelegate <NSObject>
@optional
    // TODO request colors after debounce in scrolling?
@end

@interface ECCodeView3 : UIView <UIKeyInput, UITextInputTraits, UITextInput>

@property (nonatomic, assign) id <ECCodeViewDelegate> delegate;

/// The text displayed by the code view.
@property (nonatomic, copy) NSString *text;

/// The text insets from the view's border.
@property (nonatomic) UIEdgeInsets textInsets;

#pragma mark UITextInput properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@end
