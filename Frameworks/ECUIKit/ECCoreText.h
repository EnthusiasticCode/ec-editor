//
//  ECCoreText.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 23/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreText/CoreText.h>


// TODO move to utility
typedef void (^RectBlock)(CGRect rect);

/// Returns true if the given index is contained in the given range. False otherwhise.
inline _Bool ECCoreTextIndexInRange(CFIndex index, CFRange range);

/// Within a range in the given lines, this function search for the line containing the given string location. If resultLine is not NULL, it will contain the referene to the found line. The function will return kCFNotFound if the line has not been found.
CFIndex ECCTFrameGetLineContainingStringIndex(CTFrameRef frame, CFIndex location, CFRange within, CTLineRef *resultLine);

/// For every line that contains part of the given string range, a rect is generated and passed to the given block.
void ECCTFrameProcessRectsOfLinesInStringRange(CTFrameRef frame, CFRange range, RectBlock block);

/// Returns the bounding rect for the string range in the given frame.
CGRect ECCTFrameGetBoundRectOfLinesForStringRange(CTFrameRef frame, CFRange range);

/// Returns the range of lines that contains the given string range.
CFRange ECCTFrameGetLineRangeOfStringRange(CTFrameRef frame, CFRange stringRange);

/// Search for the string index within the given range in the frame's lines that is closest to the provided point. The should consider to have origin at the frame's origins. If an empty string range is specified, the whole frame is searched.
CFIndex ECCTFrameGetClosestStringIndexInRangeToPoint(CTFrameRef frame, CFRange stringRange, CGPoint point);

/// Calculate the actual used rectangle that fits the given frame.
CGRect ECCTFrameGetUsedRect(CTFrameRef frame, _Bool constrainedWidth);

#pragma mark Enumeration

typedef void (^lineElementBlock)(CTLineRef line, CFIndex index, _Bool *stop);
void ECCTFrameEnumerateLinesWithBlock(CTFrameRef frame, lineElementBlock block);

#pragma mark Mutli array functions

/// Fill the array with frames created from the given framesetter and all with the same path.
/// All frames before the given stringIndex will be generated if not already present or if force is set to YES.
/// The frame containing the given string index will be generated containing all remaining characters up through string index or untill it's full if fillLastFrame is YES.
/// The return value is the index in the array at which the frame containing the given string index can be found or -1 if an error occured.
CFIndex ECCTFrameArrayFillFramesUpThroughStringIndex(CFMutableArrayRef frames, CFIndex stringIndex, CTFramesetterRef framesetter, CGPathRef path, _Bool fillLastFrame, _Bool force);

/// Gets the frame containing the given string index in the frame array.
CTFrameRef ECCTFrameArrayGetFrameContainingStringIndex(CFArrayRef frames, CFIndex stringIndex);


