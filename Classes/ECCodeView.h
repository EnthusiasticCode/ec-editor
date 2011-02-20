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

// TODO
// 1. Draw plain text DONE
// 2. Text selection
// 3. Conform to text input/text editing
// 4. Add coloring function
//
// References
// search for "drawing managing text" in documentation.

extern const NSString* ECCodeStyleDefaultTextName;
extern const NSString* ECCodeStyleKeywordName;
extern const NSString* ECCodeStyleCommentName;

// TODO It's ok to derive from UIScrollView to have scroll functionalities
// and add "find marks" but zoom functionalities should be disabled to
// permit 2 finger tap zone selection.
@interface ECCodeView : UIScrollView <UIKeyInput, UITextInputTraits, UITextInput> {
@private
    // Content
    NSMutableAttributedString *content;
    
    // Core text objects and support
    CTFramesetterRef frameSetter;
    CTFrameRef contentFrame;
    CGPoint contentFrameOrigin;
    
    // Styling objects
    NSMutableDictionary *_styles;
    NSDictionary *defaultAttributes;
    
    //
    ECTextRange *selection;
    
    // UITextInputTraits objects
    UIKeyboardType keyboardType;
    
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

- (void)setAttributes:(NSDictionary*)attributes forStyleNamed:(const NSString*)aStyle;
- (void)setStyleNamed:(const NSString*)aStyle toRange:(NSRange)range;

@end
