//
//  ECMutableFileRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECMutableTextFileRenderer.h"
#import <CoreText/CoreText.h>

#pragma mark Internal data cache objects

@interface FramesetterInfo : NSObject {
@private
    /// Hold a reference to the framesetter connected with this info block. 
    /// This reference may be NULL if cleaning required the framesetter to be
    /// deallocated because not used.
    CTFramesetterRef framesetter;
    
    /// The string range in the content text that this framesetter is handling.
    CFRange stringRange;
    
    /// Get the actual rendered rect of the union of the framesetter's generated
    /// framses originated accordingly with previous framesetters.
    CGRect actualRect;
    
    // TODO editing data and string attributes cache
}
@end

@interface FrameInfo : NSObject {
@private
    /// A pointer to the framesetter's info that describe the framesetter used
    /// to render the frame.
    FramesetterInfo *framesetterInfo;
    
    /// Hold a reference to the frame connected with this info block.
    /// This reference may be NULL is the frame has been released due to no use.
    CTFrameRef frame;
    
    /// The effective string range rendered int the frame.
    CFRange stringRange;
    
    /// Rect used to render the frame. This rect should have his width equal
    /// to the frameWidth property.
    CGRect rect;
    
    /// Contains the actual size of this frame. Width may be smaler than rect's
    /// one and height is calculated from the top of the first line to the 
    /// bottom of the last rendered one.
    CGSize actualSize;
}
@end

#pragma mark Class continuations
@interface ECMutableTextFileRenderer () {
@private
    /// Dictionary of FramesetterInfo to NSMutableArray of FrameInfo.
    NSMutableDictionary *info;
}
@end

#pragma mark ECMutableTextFileRenderer Implementation
@implementation ECMutableTextFileRenderer

#pragma mark Properties
@synthesize inputStream;
@synthesize string;
@synthesize framesetterStringLengthLimit;
@synthesize framePreferredHeight;
@synthesize frameWidth;

- (void)setInputStream:(NSInputStream *)stream
{
    // Close current stream
    [inputStream close];
    [inputStream release];
    
    // Attach to new stream
    inputStream = [stream retain];
    [inputStream setDelegate:self];
    // TODO study this method to optimize
    [inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
}

#pragma mark -
#pragma mark Input stream delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            // TODO see file:///Library/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiOS4_3.iOSLibrary.docset/Contents/Resources/Documents/index.html#documentation/Cocoa/Conceptual/Streams/Articles/ReadingInputStreams.html#//apple_ref/doc/uid/20002273-BCIJHAGD
            break;
        }
    }
}

#pragma mark -
#pragma mark Rendering

- (void)drawTextInBounds:(CGRect)bounds inContext:(CGContextRef)context
{
    inputStream 
}
@end
