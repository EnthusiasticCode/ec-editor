//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextStyle.h"
#import "ECTextOverlayStyle.h"
#import "ECTextRange.h"
#import "ECTextPosition.h"

@interface ECCodeView : UIView {
@protected
    NSMutableAttributedString *text;
}

/// The text displayed by the code view.
@property (nonatomic, copy) NSString *text;

/// Return the length of the text, this method should return the same value as [text length];
@property (nonatomic, readonly) NSUInteger textLength;

#pragma mark Text style API

/// The text style used for newly added text.
@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

/// Set the given style to the text range.
- (void)setTextStyle:(ECTextStyle *)style toTextRange:(ECTextRange *)range;

/// For every range in the ranges array, the corresponding style will be applied.
- (void)setTextStyles:(NSArray *)styles toTextRanges:(NSArray *)ranges;

#pragma mark Text overlay API

/// Add an overlay to the specified text range. If alternative is YES, the alternative options in the style will be used.
- (void)addTextOverlayStyle:(ECTextOverlayStyle *)style forTextRange:(ECTextRange *)range alternative:(BOOL)alt;

/// Remove all text overlays with the given style.
- (void)clearTextOverlayWithStyle:(ECTextOverlayStyle *)style;

/// Remove all text overlays.
- (void)clearAllTextOverlays;

@end
