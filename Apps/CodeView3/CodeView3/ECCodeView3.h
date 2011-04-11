//
//  ECCodeView3.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextRange.h"
#import "ECTextPosition.h"
#import "ECTextStyle.h"

@protocol ECCodeViewDelegate <NSObject>
@optional
    // TODO request colors after debounce in scrolling?
@end

@interface ECCodeView3 : UIView <UIKeyInput, UITextInputTraits, UITextInput>

@property (nonatomic, assign) id <ECCodeViewDelegate> delegate;

#pragma mark Provide Text Content and Properties

/// The text displayed by the code view.
/// This text has to be a \c NSMutableAttributedString and will be retained to avoid potential expensive copies of large strings. 
@property (nonatomic, retain) NSMutableAttributedString *text;

/// Set the text of the code view applying the default text attributes to it if required.
- (void)setText:(NSMutableAttributedString *)string applyDefaultAttributes:(BOOL)defaultAttributes;

/// The text insets from the view's border.
@property (nonatomic) UIEdgeInsets textInsets;

/// Set the frame of the receiver autoresizing it's height to fit the entire text if so specified.
- (void)setFrame:(CGRect)frame autosizeHeightToFitText:(BOOL)autosizeHeight;

#pragma mark Text Style API

/// The text style used for newly added text.
@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

/// Set the given style to the text range.
- (void)setTextStyle:(ECTextStyle *)style toTextRange:(ECTextRange *)range;

/// For every range in the ranges array, the corresponding style will be applied.
- (void)setTextStyles:(NSArray *)styles toTextRanges:(NSArray *)ranges;

#pragma mark UITextInput Properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@end
