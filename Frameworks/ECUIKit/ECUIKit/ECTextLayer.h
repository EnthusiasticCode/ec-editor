//
//  ECTextLayer.h
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

/// The \c ECTextLayer provides advanced text layout and rendering of attributed strings. The first line is aligned to the top of the layer.
@interface ECTextLayer : CALayer

/// The text to be rendered by the receiver.
@property (nonatomic, assign) NSAttributedString *string;

/// Determines whether the text is wrapped to fit within the receiver’s bounds.
@property (getter = isWrapped) BOOL wrapped;

/// Gets the core text frame rendered for this layer.
@property (nonatomic, readonly) CTFrameRef CTFrame;

/// Gets the core text frame size.
@property (nonatomic, readonly) CGRect CTFrameRect;

/// The array of \c CTLineRef generated from the string.
@property (nonatomic, readonly) CFArrayRef CTFrameLines;

/// Invalidate the content taht will be marked as needing redraw.
- (void)setNeedsTextRendering;

/// Calculates and returns a size that best fits the receiver’s string content.
- (CGSize)sizeThatFits:(CGSize)size;

@end
