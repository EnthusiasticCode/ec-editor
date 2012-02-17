//
//  CodeView.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TextRenderer.h"

/// The placeholder status of the text to which this attribute applies. Value must be a CFBooleanRef object. Default is false. This attribute does not alter the display of the text but the behaviour of the code view selection.
extern NSString * const CodeViewPlaceholderAttributeName;

typedef void (^CodeViewTileSetupBlock)(CGContextRef context, CGRect rect);

@class CodeView, KeyboardAccessoryView;

@protocol CodeViewDataSource <TextRendererDataSource>
@optional

/// Returns a value that indicate if the codeview can edit the dataSource
/// in the specified text range. By default, if not implemented, this method will
/// return YES if codeView:commitString:forTextInRange: is implemented.
- (BOOL)codeView:(CodeView *)codeView canEditTextInRange:(NSRange)range;

/// Commit a change for the given range with the given string.
/// This operation will not update the renered text. It sould be done using 
/// updateStringFromStringRange:toStringRange:
- (void)codeView:(CodeView *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range;

/// If implemented, indicate that the data source support completion of words.
/// The view controller returned from this method will be presented to the user
/// when a completion will be requested.
/// The method receive a range of the string to complete.
/// This method is supposed to use codeView:stringInRange: to retrieve the part
/// of text to complete. An action in the view controller should call
/// codeView:commitString:forTextInRange: to actually complete the word.
- (UIViewController *)codeView:(CodeView *)codeView viewControllerForCompletionAtTextInRange:(NSRange)range;

/// If implemented, return the attribute value at the given index. 
/// If effectiveRange is not NULL, the effective range of the given attribute found at index is returned.
- (id)codeView:(CodeView *)codeView attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange;

@end

@protocol CodeViewDelegate <UIScrollViewDelegate>
@optional

/// This method allow the delegate to substitute the inserted text. 
/// The selection range after the insertion can also be altered.
/// Return nil to reproduce the default behaviours.
- (NSString *)codeView:(CodeView *)codeView replaceInsertedText:(NSString *)insertedText selectionAfterInsertion:(NSRange *)selectionAfterInsertion;

/// Called when the user tap on a line number. Line numbers starts from 1, if 0 is returned, it has to be considered an invalid line.
- (void)codeView:(CodeView *)codeView selectedLineNumber:(NSUInteger)lineNumber;

/// Returns if the codeview should show its keyboard accessory view in the given view with the given frame. 
/// The provided frame is relative to the given view. The implementer can return a different view and frame. The frame will be automatically adjusted after this method if the accessovy view 'flipped' property will be set to YES.
- (BOOL)codeView:(CodeView *)codeView shouldShowKeyboardAccessoryViewInView:(UIView **)view withFrame:(CGRect *)frame;

/// Informs the delegate that the accessory view has been displayed in the given view with the given frame.
- (void)codeView:(CodeView *)codeView didShowKeyboardAccessoryViewInView:(UIView *)view withFrame:(CGRect)frame;

/// Returns if the codeview should hide its keyboard accessory view.
- (BOOL)codeViewShouldHideKeyboardAccessoryView:(CodeView *)codeView;

/// Informs the delegate that the accessory view has been hidden.
- (void)codeViewDidHideKeyboardAccessoryView:(CodeView *)codeView;

/// Called when the code view is about to change its selection from user interaction.
- (void)selectionWillChangeForCodeView:(CodeView *)codeView;

/// Called when the code view changes its selection from user interaction.
- (void)selectionDidChangeForCodeView:(CodeView *)codeView;

@end


@interface CodeView : UIScrollView <TextRendererDelegate, UIKeyInput, UITextInputTraits, UITextInput>

@property (nonatomic, weak) id<CodeViewDelegate> delegate;
@property (nonatomic, weak) id<CodeViewDataSource> dataSource;

#pragma mark Advanced Initialization and Configuration

/// Initialize a codeview with external renderer and rendering queue.
/// The codeview initialized with this method will be set to not own the 
/// renderer and will use it only as a consumer.
- (id)initWithFrame:(CGRect)frame renderer:(TextRenderer *)aRenderer;

/// Renderer used in the codeview.
@property (nonatomic, readonly, strong) TextRenderer *renderer;

/// Indicates if the codeview is in editing mode and it's content can be modified by the user.
@property (nonatomic, getter = isEditing) BOOL editing;

#pragma mark Managing Text Content

/// Access the full text showed in the code view. This methods uses the datasource to retrieve the text.
@property (nonatomic, strong, readonly) NSString *text;

/// Text insets for the rendering.
@property (nonatomic) UIEdgeInsets textInsets;

/// Returns the text range that is currently visible in the receiver's bounds.
- (NSRange)visibleTextRange;

#pragma mark Style

/// Specify the color of caret.
@property (nonatomic, strong) UIColor *caretColor;

/// Specify the color of the selection rect.
@property (nonatomic, strong) UIColor *selectionColor;

#pragma mark Code Display Enhancements

/// Indicates if line numbers should be displayed according to line numbers properties.
@property (nonatomic, getter = isLineNumbersEnabled) BOOL lineNumbersEnabled;

/// The width to reserve for line numbers left inset. This value will not increase
/// the text insets; textInsets.left must be greater than this number.
@property (nonatomic) CGFloat lineNumbersWidth;

/// Font to be used for rendering line numbers
@property (nonatomic, strong) UIFont *lineNumbersFont;

/// Color to be used for rendering line numbers
@property (nonatomic, strong) UIColor *lineNumbersColor;

/// Color to be used as the background of line numbers.
@property (nonatomic, strong) UIColor *lineNumbersBackgroundColor;

/// Add a layer pass that will be used by the renderer for overlays or underlays.
- (void)addPassLayerBlock:(TextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey;

/// In addition to the pass layer block, this method also add a block to be executed before a tile is rendered
/// and after it's rendered.
- (void)addPassLayerBlock:(TextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey setupTileBlock:(CodeViewTileSetupBlock)setupBlock cleanupTileBlock:(CodeViewTileSetupBlock)cleanupBlock;

/// Removes a layer pass from the rendering process.
- (void)removePassLayerForKey:(NSString *)passKey;

/// Scrolls the given range to be visible and flashes it for a brief moment to draw user attention on it.
- (void)flashTextInRange:(NSRange)textRange;

#pragma mark Accessories

/// The popover controller to use to show magnifications.
@property (nonatomic, strong) Class magnificationPopoverControllerClass;

/// Gets the receiver's accessory view.
@property (nonatomic, strong) KeyboardAccessoryView *keyboardAccessoryView;

/// Set keyboard visibility.
- (void)setKeyboardAccessoryViewVisible:(BOOL)visible animated:(BOOL)animated;

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
@property (nonatomic, readonly, copy) RectSet *selectionRects;

/// Returns the currently selected text.
- (NSString *)selectedText;

@end

@interface CodeView (TextRendererForwarding)

/// Invalidate the text making the receiver redraw it.
- (void)updateAllText;

/// Invalidate a particular section of the text making the reveiver redraw it.
- (void)updateTextFromStringRange:(NSRange)originalRange toStringRange:(NSRange)newRange;

@end

/// View used to flash a text range.
@interface CodeFlashView : UIView

@property (nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

/// Flashes the receiver by showing and increasing it's size for half of the given duration
/// and than reversing the animation for the remaining half. The receiver will be added
/// and removed automatically to the given view.
- (void)flashInRect:(CGRect)rect view:(UIView *)view withDuration:(NSTimeInterval)duration;

@end
