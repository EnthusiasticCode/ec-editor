//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "ECTextRange.h"
#import "ECCaretView.h"

// TODO
// 1. Draw plain text DONE
// 2. Text selection PARTIAL
// 3. Conform to text input/text editing DONE
// 4. Add coloring/styling function
//
// - Fix up/down cursor movement with keyboard
// - Create property for block like void (^Decoration)(CGMutablePathRef res, CGRect rect, NSUInteger index, NSUInteger count);
// - Remove blinking cursor?
//
// References
// search for "drawing managing text" in documentation.

extern const NSString *ECCodeStyleDefaultTextName;
extern const NSString *ECCodeStyleKeywordName;
extern const NSString *ECCodeStyleCommentName;
extern const NSString *ECCodeStyleIdentifierName;
extern const NSString *ECCodeStyleLiteralName;
extern const NSString *ECCodeStyleReferenceName;
extern const NSString *ECCodeStyleDeclarationName;
extern const NSString *ECCodeStylePreprocessingName;

typedef void (^DrawOverlayInContext)(CGContextRef ctx, CGRect rct, NSDictionary* attr);
extern const NSString *ECCodeOverlayColorName;
extern const NSString *ECCodeOverlayDrawBlockName;

// TODO It's ok to derive from UIScrollView to have scroll functionalities
// and add "find marks" but zoom functionalities should be disabled to
// permit 2 finger tap zone selection.
@interface ECCodeView : UIView <UIKeyInput, UITextInputTraits, UITextInput> {
@private
    // Content
    NSMutableAttributedString *content;
    
    // Core text objects and support
    CTFramesetterRef frameSetter;
    CTFrameRef contentFrame;
    CGRect contentFrameRect;
    UIEdgeInsets contentFrameInset;
    
    // Styling objects
    NSMutableDictionary *_styles;
    NSDictionary *defaultAttributes;
    
    // UITextInput objects
    ECTextRange *selection;
    NSRange markedRange;
    CGRect markedRangeDirtyRect;
    UITextInputStringTokenizer *tokenizer;
    
    // UITextInputTraits objects
    UIKeyboardType keyboardType;
    
    // Tap recognizers
    UIGestureRecognizer *focusRecognizer;
    UIGestureRecognizer *tapRecognizer;
    UIGestureRecognizer *doubleTapRecognizer;
    UIGestureRecognizer *tapHoldRecognizer;
    
    // Caret
    ECCaretView *caretView;
    
    // Overlays
    NSMutableDictionary *overlayStyles;
    NSMutableDictionary *overlays;
    
    // Flags
    // TODO create smaller struct?
    BOOL contentFrameInvalid;
}

@property (nonatomic, retain) NSString *text;

// Dictionary containig styles for text in the editor.
// It is expected to contain strings as keys representing a text type
// (ie: ECCodeDefaultText, ECCodeKeyword, ...) and dictionaries of 
// core text attributes.
@property (nonatomic, copy) NSDictionary *styles;

@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;
@property (nonatomic, copy) NSDictionary *markedTextStyle;

// Declare a style. After this declaration one can refer to the named style
// in the setStyleNamed:toRange: API.
- (void)setAttributes:(NSDictionary*)attributes forStyleNamed:(const NSString*)aStyle;

// Apply a style to the given range.
// TODO rename to addStyleNamed ?
// TODO API to apply a dictionary of style -> array of ranges. applyStyles: toRanges:
- (void)setStyleNamed:(const NSString*)aStyle toRange:(NSRange)range;

//
// Overlays API
//
@property (nonatomic, copy) DrawOverlayInContext defaultOverlayDrawBlock;
- (void)setAttributes:(NSDictionary *)attributes forOverlayNamed:(NSString *)overlay;
- (void)addOverlayNamed:(NSString *)overlay toRange:(NSRange)range;
- (void)removeAllOverlays;
- (void)removeAllOverlaysNamed:(NSString *)overlay;

@end
