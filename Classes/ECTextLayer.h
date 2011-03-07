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
@property (nonatomic, readonly) CGSize CTFrameSize;

/// The array of \c CTLineRef generated from the string.
@property (nonatomic, readonly) CFArrayRef CTLines;

/// Invalidate the content taht will be 
- (void)invalidateContent;

/// Asks the layer to calculate and return the size that best fits its contents.
- (CGSize)sizeThatFits:(CGSize)size;

@end

// TODO move to utility
typedef void (^RectBlock)(CGRect rect);

/// Returns true if the given index is contained in the given range. False otherwhise.
inline _Bool ECCoreTextIndexInRange(CFIndex index, CFRange range);

/// Within a range in the given lines, this function search for the line containing the given string location. If resultLine is not NULL, it will contain the referene to the found line. The function will return kCFNotFound if the line has not been found.
CFIndex ECCoreTextLineContainingLocation(CFArrayRef lines, CFIndex location, CFRange within, CTLineRef *resultLine);

/// For every line that contains part of the given string range, a rect is generated and passed to the given block.
void ECCoreTextProcessRectsOfLinesInStringRange(CTFrameRef frame, CFRange range, RectBlock block);

/// Returns the bounding rect for the string range in the given frame.
CGRect ECCoreTextBoundRectOfLinesForStringRange(CTFrameRef frame, CFRange range);

