//
//  ECTextRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextRenderer.h"
#import <CoreText/CoreText.h>

#pragma mark TextSegment
// Internal working notes:
// - The renderer keeps an array of ordered framesetter informations:
//    > framesetter string range: the range of the total input used to
//      generate the framesetter. (order cryteria)
//    > framesetter: to be cached undefinetly untill clearCache message;
//    > frame: that cover the entire framesetter's text and is reused
//      when wrap size changes;
//    > frame info cache: that cache wrap sizes to frame infos;
//    > actual size: cache the actual size of rendered text.
@interface TextSegment : NSObject {
@private
    NSRange stringRange;
    
    CTFramesetterRef framesetter;
    CTFrameRef frame;
    
    // to decide: either keep a cache of frames or always rerender
    // a single frame on wrap changes..
}
@end

#pragma mark -
#pragma mark ECTextRenderer

@implementation ECTextRenderer

@end
