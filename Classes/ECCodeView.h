//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "ECTextRange.h"

// TODO
// 1. Draw plain text DONE
// 2. Text selection PARTIAL
// 3. Conform to text input/text editing DONE
// 4. Add coloring/styling function
// 5. Customizable autocomplition
// Misc:
// - ECCodeOverlayLayer as CALayer to draw overlay to add to view.layer addSublayer instead of draw in drawRect. see http://lists.apple.com/archives/quicktime-api/2008/Sep/msg00184.html or better use a delegate drawLayer:inContext: see http://www.raywenderlich.com/2502/introduction-to-calayers-tutorial
// - sizeThatFits and scrollview
// - Fix up/down cursor movement with keyboard
// - Create property for block like void (^Decoration)(CGMutablePathRef res, CGRect rect, NSUInteger index, NSUInteger count);
// - Remove blinking cursor? or not, cursor should be a separate view like now to do more prothings jet to think about
// - User layer.cornerRadius for always rounded views
//
// References
// search for "drawing managing text" in documentation.

enum ECCodeViewMode {
    ECCodeViewModeNormal,
    ECCodeViewModeEditable,
    ECCodeViewModeRTC
};

extern const NSString *ECCodeStyleDefaultTextName;
extern const NSString *ECCodeStyleKeywordName;
extern const NSString *ECCodeStyleCommentName;

typedef void (^DrawOverlayBlock)(CGContextRef ctx, CGRect rct, NSDictionary* attr);
extern const NSString *ECCodeOverlayAttributeColorName;
extern const NSString *ECCodeOverlayAttributeDrawBlockName;

@interface ECCodeView : UIView <UIKeyInput, UITextInputTraits, UITextInput> {
@private
    // Content and content rendering
    NSMutableAttributedString *content;
    CTFramesetterRef frameSetter;
    CTFrameRef contentFrame;
    CGRect contentFrameRect;
    UIEdgeInsets contentFrameInset;
    
    // Styling and overlay
    NSMutableDictionary *styles;
    NSDictionary *defaultAttributes;
    NSMutableDictionary *overlayStyles;
    NSMutableDictionary *overlays;
    
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
    
    // Caret/Selection overlay
    CALayer *selectionLayer;
    CABasicAnimation *blinkAnimation;
    
    // Flags
    // TODO create smaller struct?
    BOOL contentFrameInvalid;
}

// Gets or set the mode of the CodeView.
// Normal mode avoid editing;
// Editing mode permit the code in the view to be edited;
// RTC reformat the code and permit the usage of RTC API.
@property (nonatomic) enum ECCodeViewMode mode;

// Gets or set the text for the CodeView.
@property (nonatomic, retain) NSString *text;

// Dictionary containig styles for text in the editor.
// It is expected to contain strings as keys representing a text type
// (ie: ECCodeDefaultText, ECCodeKeyword, ...) and dictionaries of 
// core text attributes.
@property (nonatomic, copy) NSDictionary *styles;

@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@property (nonatomic, retain) UIColor *selectionColor;

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
// TODO make it more similar to say CALayer animations api
@property (nonatomic, copy) DrawOverlayBlock defaultOverlayDrawBlock;
- (void)setAttributes:(NSDictionary *)attributes forOverlayNamed:(NSString *)overlay;
- (void)addOverlayNamed:(NSString *)overlay toRange:(NSRange)range;
- (void)removeAllOverlays;
- (void)removeAllOverlaysNamed:(NSString *)overlay;

@end
