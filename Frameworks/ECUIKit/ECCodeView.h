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

@protocol ECCodeViewDataSource <ECCodeViewBaseDataSource>
@optional

/// Returns a value that indicate if the codeview can edit the datasource
/// in the specified text range.
- (BOOL)codeView:(ECCodeView *)codeView canEditTextInRange:(NSRange)range;

/// Commit a change for the given range with the given string.
/// The datasource is responsible for calling one of the update methods of the 
/// codeview after the text has been changed.
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


@interface ECCodeView : ECCodeViewBase <UIKeyInput, UITextInputTraits, UITextInput>

@property (nonatomic, weak) id<ECCodeViewDataSource> datasource;

#pragma mark Managing the Navigator

@property (nonatomic) CGFloat navigatorWidth;

@property (nonatomic, strong) UIColor *navigatorBackgroundColor;

@property (nonatomic, getter = isNavigatorVisible) BOOL navigatorVisible;

#pragma mark Completion

- (void)showCompletionPopoverAtCursor;

#pragma mark UITextInput Properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, weak) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@end
