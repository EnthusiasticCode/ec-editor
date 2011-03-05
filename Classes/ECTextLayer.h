//
//  ECTextLayer.h
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

/// The \c ECTextLayer provides advanced text layout and rendering of attributed strings. The first line is aligned to the top of the layer.
@interface ECTextLayer : CALayer

/// The text to be rendered by the receiver.
@property (nonatomic, assign) NSAttributedString *string;

/// Determines whether the text is wrapped to fit within the receiver’s bounds.
@property (getter = isWrapped) BOOL wrapped;

/// The array of \c CTLineRef generated from the string.
@property (nonatomic, readonly) CFArrayRef CTLines;

/// Invalidate the content taht will be 
- (void)invalidateContent;

/// Asks the layer to calculate and return the size that best fits its contents.
- (CGSize)sizeThatFits:(CGSize)size;

@end
