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

// The placeholder status of the text to which this attribute applies. Value must be a CFBooleanRef object. Default is false. This attribute does not alter the display of the text but the behaviour of the code view selection.
extern NSString * const CodeViewPlaceholderAttributeName;

typedef void (^CodeViewTileSetupBlock)(CGContextRef context, CGRect rect);

// The result of an autoindentation block
typedef enum {
  CodeViewAutoIndentKeep,         // Keep the current indentation
  CodeViewAutoIndentIncrease,     // Increase the indentation by one level from the next line
  CodeViewAutoIndentDecrease,     // Decrese one level of indentation from the current line
  CodeViewAutoIndentIncreaseOnce, // Increase the level of indentation only for one line
  CodeViewAutoIndentIgnoreOnce    // Remove all indentation for the line
} CodeViewAutoIndentResult;
typedef CodeViewAutoIndentResult (^CodeViewAutoIndentationForLineBlock)(NSString *line);

@class CodeView, KeyboardAccessoryView;

@protocol CodeViewDelegate <UIScrollViewDelegate>
@optional

// Called when the user tap on a line number. Line numbers starts from 1, if 0 is returned, it has to be considered an invalid line.
- (void)codeView:(CodeView *)codeView selectedLineNumber:(NSUInteger)lineNumber;

// Returns if the codeview should show its keyboard accessory view in the given view with the given frame.
// The provided frame is relative to the given view. The implementer can return a different view and frame. The frame will be automatically adjusted after this method if the accessovy view 'flipped' property will be set to YES.
- (BOOL)codeView:(CodeView *)codeView shouldShowKeyboardAccessoryViewOnNotification:(NSNotification *)note inView:(UIView **)view withFrame:(CGRect *)frame;

#pragma mark Insersion modificators

// This method allow the delegate to substitute the inserted text. 
// The selection range after the insertion can also be altered.
// Return nil to reproduce the default behaviours.
- (NSString *)codeView:(CodeView *)codeView replaceInsertedText:(NSString *)insertedText selectionAfterInsertion:(NSRange *)selectionAfterInsertion;

@end


@interface CodeView : UIScrollView <TextRendererDelegate, UIKeyInput, UITextInputTraits, UITextInput>

@property (nonatomic, weak) id<CodeViewDelegate> delegate;

@property (nonatomic, copy) NSString *text;

#pragma mark Advanced Initialization and Configuration

// Initialize a codeview with external renderer and rendering queue.
// The codeview initialized with this method will be set to not own the 
// renderer and will use it only as a consumer.
- (id)initWithFrame:(CGRect)frame renderer:(TextRenderer *)aRenderer;

// Renderer used in the codeview.
@property (nonatomic, readonly, strong) TextRenderer *renderer;

// Indicates if the codeview is in editing mode and it's content can be modified by the user.
@property (nonatomic, getter = isEditing) BOOL editing;

// Dictionary of smart pairing strings with an input string as key and a paring string as value.
// String pairing will insert the paired string and position the cursor before it. 
// Deleting the input string with backspace will result in also removin the paired string.
@property (nonatomic, strong) NSDictionary *pairingStringDictionary;

// A block that will be used to determine how a line of text should be indented.
// This block will be automatically used when a single new line will be inserted.
@property (nonatomic, strong) CodeViewAutoIndentationForLineBlock autoIndentationBlock;

// A string used to indend a line by one level. Default to 4 spaces.
@property (nonatomic, strong) NSString *autoIndentationString;

#pragma mark Managing Text Content

// Text insets for the rendering.
@property (nonatomic) UIEdgeInsets textInsets;

// Returns the text range that is currently visible in the receiver's bounds.
- (NSRange)visibleTextRange;

#pragma mark Style

// Specify the color of caret.
@property (nonatomic, strong) UIColor *caretColor;

// Specify the color of the selection rect.
@property (nonatomic, strong) UIColor *selectionColor;

#pragma mark Code Display Enhancements

// Indicates if line numbers should be displayed according to line numbers properties.
@property (nonatomic, getter = isLineNumbersEnabled) BOOL lineNumbersEnabled;

// The width to reserve for line numbers left inset. This value will not increase
// the text insets; textInsets.left must be greater than this number.
@property (nonatomic) CGFloat lineNumbersWidth;

// Font to be used for rendering line numbers
@property (nonatomic, strong) UIFont *lineNumbersFont;

// Color to be used for rendering line numbers
@property (nonatomic, strong) UIColor *lineNumbersColor;

// Color to be used as the background of line numbers.
@property (nonatomic, strong) UIColor *lineNumbersBackgroundColor;

// Add a layer pass that will be used by the renderer for overlays or underlays.
- (void)addPassLayerBlock:(TextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey;

// In addition to the pass layer block, this method also add a block to be executed before a tile is rendered
// and after it's rendered.
- (void)addPassLayerBlock:(TextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey setupTileBlock:(CodeViewTileSetupBlock)setupBlock cleanupTileBlock:(CodeViewTileSetupBlock)cleanupBlock;

// Removes a layer pass from the rendering process.
- (void)removePassLayerForKey:(NSString *)passKey;

// Scrolls the given range to be visible and flashes it for a brief moment to draw user attention on it.
- (void)flashTextInRange:(NSRange)textRange;

#pragma mark Accessories

// The popover backgorund view for the popover used to show magnifications.
@property (nonatomic, strong) Class magnificationPopoverBackgroundViewClass;

// Gets the receiver's accessory view.
@property (nonatomic, strong) KeyboardAccessoryView *keyboardAccessoryView;

// Indicates if the keyboard accessory view is visible.
@property (nonatomic, readonly) BOOL keyboardAccessoryViewVisible;

// Presents the keyboard accessory view in the given view and position it considering the keyboard frame
- (void)presentKeyboardAccessoryViewWithKeyboardFrame:(CGRect)keyboardFrame inView:(UIView *)targetView animated:(BOOL)animated;
- (void)dismissKeyboardAccessoryViewAnimated:(BOOL)animated;

#pragma mark UITextInput Properties

// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, weak) id<UITextInputDelegate> inputDelegate;

// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly, weak) id<UITextInputTokenizer> tokenizer;

// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

#pragma mark Selection Management

// Gets or set the selection like selectedTextRange but with a plain NSRange.
@property (nonatomic) NSRange selectionRange;

// Gets the selection rects of the current selection. If the selection is empty, this methods returns the caret rect. If no selection returns nil.
@property (nonatomic, readonly, copy) RectSet *selectionRects;

// Returns the currently selected text.
- (NSString *)selectedText;

@end

// Forwarding calls to internal mutable attributed string
@interface CodeView (AttributedTextForwarding)

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange;

@end

// Forwarding calls to text rendere
@interface CodeView (TextRendererForwarding)

@property (nonatomic, strong) NSDictionary *defaultTextAttributes;

@end

// View used to flash a text range.
@interface CodeFlashView : UIView

@property (nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

// Flashes the receiver by showing and increasing it's size for half of the given duration
// and than reversing the animation for the remaining half. The receiver will be added
// and removed automatically to the given view.
- (void)flashInRect:(CGRect)rect view:(UIView *)view withDuration:(NSTimeInterval)duration;

@end
