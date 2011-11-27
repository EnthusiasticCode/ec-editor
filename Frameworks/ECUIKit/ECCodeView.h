//
//  ECCodeView.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeViewBase.h"

/// The placeholder status of the text to which this attribute applies. Value must be a CFBooleanRef object. Default is false. This attribute does not alter the display of the text but the behaviour of the code view selection.
extern NSString * const ECCodeViewPlaceholderAttributeName;


@class ECCodeView, ECKeyboardAccessoryView;

@protocol ECCodeViewDataSource <ECTextRendererDataSource>
@optional

/// Returns a value that indicate if the codeview can edit the dataSource
/// in the specified text range. By default, if not implemented, this method will
/// return YES if codeView:commitString:forTextInRange: is implemented.
- (BOOL)codeView:(ECCodeView *)codeView canEditTextInRange:(NSRange)range;

/// Commit a change for the given range with the given string.
/// This operation will not update the renered text. It sould be done using 
/// updateStringFromStringRange:toStringRange:
- (void)codeView:(ECCodeView *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range;

/// If implemented, indicate that the data source support completion of words.
/// The view controller returned from this method will be presented to the user
/// when a completion will be requested.
/// The method receive a range of the string to complete.
/// This method is supposed to use codeView:stringInRange: to retrieve the part
/// of text to complete. An action in the view controller should call
/// codeView:commitString:forTextInRange: to actually complete the word.
- (UIViewController *)codeView:(ECCodeView *)codeView viewControllerForCompletionAtTextInRange:(NSRange)range;

@end

@protocol ECCodeViewDelegate <UIScrollViewDelegate>
@optional

/// Returns if the codeview should show its keyboard accessory view in the given view with the given frame. 
/// The provided frame is relative to the given view. The implementer can return a different view and frame. The frame will be automatically adjusted after this method if the accessovy view 'flipped' property will be set to YES.
- (BOOL)codeView:(ECCodeView *)codeView shouldShowKeyboardAccessoryViewInView:(UIView **)view withFrame:(CGRect *)frame;

/// Informs the delegate that the accessory view has been displayed in the given view with the given frame.
- (void)codeView:(ECCodeView *)codeView didShowKeyboardAccessoryViewInView:(UIView *)view withFrame:(CGRect)frame;

/// Returns if the codeview should hide its keyboard accessory view.
- (BOOL)codeViewShouldHideKeyboardAccessoryView:(ECCodeView *)codeView;

/// Informs the delegate that the accessory view has been hidden.
- (void)codeViewDidHideKeyboardAccessoryView:(ECCodeView *)codeView;

@end


@interface ECCodeView : ECCodeViewBase <UIKeyInput, UITextInputTraits, UITextInput>

@property (nonatomic, weak) id<ECCodeViewDelegate> delegate;
@property (nonatomic, weak) id<ECCodeViewDataSource> dataSource;

#pragma mark Style

/// Specify the color of caret.
@property (nonatomic, strong) UIColor *caretColor;

/// Specify the color of the selection rect.
@property (nonatomic, strong) UIColor *selectionColor;

#pragma mark Accessories

/// The popover controller to use to show magnifications.
@property (nonatomic, strong) Class magnificationPopoverControllerClass;

/// Gets the receiver's accessory view.
@property (nonatomic, strong) ECKeyboardAccessoryView *keyboardAccessoryView;

#pragma mark UITextInput Properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, weak) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly, weak) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

#pragma mark Selection Management

/// Gets or set the selection like selectedTextRange but with a plain NSRange.
@property (nonatomic) NSRange selectionRange;

/// Gets the selection rects of the current selection. If the selection is empty, this methods returns the caret rect. If no selection returns nil.
@property (nonatomic, readonly, copy) ECRectSet *selectionRects;

@end
