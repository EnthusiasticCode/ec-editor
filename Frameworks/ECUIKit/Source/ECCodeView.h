//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextLayer.h"
#import "ECTextStyle.h"
#import "ECTextOverlayStyle.h"
#import "ECTextRange.h"
#import "ECTextPosition.h"

@interface ECCodeView : UIView {
@protected
    // TODO create a setNeedsTextRendering and make this layer private
    ECTextLayer *textLayer;
    NSMutableAttributedString *text;
}

/// The text displayed by the code view.
@property (nonatomic, copy) NSString *text;

/// Return the length of the text, this method should return the same value as [text length];
@property (nonatomic, readonly) NSUInteger textLength;

/// Marks the receiver’s text as needing to be redrawn.
- (void)setNeedsTextRendering;

#pragma mark Text style API

/// The text style used for newly added text.
@property (nonatomic, retain) ECTextStyle *defaultTextStyle;

/// Set the given style to the text range.
- (void)setTextStyle:(ECTextStyle *)style toTextRange:(ECTextRange *)range;

/// For every range in the ranges array, the corresponding style will be applied.
- (void)setTextStyles:(NSArray *)styles toTextRanges:(NSArray *)ranges;

#pragma mark Text overlay API

/// Add a layer as a text overlay. The layer will be retained by the view and will be resized to match the text layer frame. The name of the layer will be used as key to access the layer from other methods such as \c removeTextOverlayLayerWithKey:. If the layer has no name a key will be generated and returned by the method.
- (NSString *)addTextOverlayLayer:(CALayer *)layer;

/// Add a text overlay layer to the specified text range. If this function is called multiple times with the same style (styles having the same name), the given range will be added to the already existing layer. The style's name will be used as key to retrieve the layer in methods as \c removeTextOverlayLayerWithKey:.
- (void)addTextOverlayLayerWithStyle:(ECTextOverlayStyle *)style forTextRange:(ECTextRange *)range;

/// Remove text overlay layer with the given style.
- (void)removeTextOverlayLayerWithStyle:(ECTextOverlayStyle *)style;

/// Remove text overlay layer with the given key.
- (void)removeTextOverlayLayerWithKey:(NSString *)key;

/// Remove all text overlays.
- (void)removeAllTextOverlays;

@end
