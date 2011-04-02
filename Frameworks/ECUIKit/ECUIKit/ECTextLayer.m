//
//  ECTextLayer.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextLayer.h"
#import "ECCoreText.h"


@interface ECTextLayer () {
    BOOL framesetterInvalid;
    CGFloat wrapWidth;
}

@property (nonatomic, readonly) CTFramesetterRef CTFrameSetter;

@end

#pragma mark -

@implementation ECTextLayer

#pragma mark Properties

@synthesize string;
@synthesize wrapped;
@synthesize CTFrameSetter;
@synthesize CTFrame;
@synthesize CTFrameRect;

- (CFArrayRef)CTFrameLines
{
    return CTFrameGetLines(self.CTFrame);
}

- (void)setString:(NSAttributedString *)aString
{
    string = aString;
    framesetterInvalid = YES;
}

#pragma mark CALayer methods

//- (void)setBounds:(CGRect)bounds
//{
//    [super setBounds:bounds];
//    [self setNeedsTextRendering];
//}

- (BOOL)isGeometryFlipped
{
    return YES;
}

- (CGSize)preferredFrameSize
{
    return self.CTFrameRect.size;
}

 - (void)drawInContext:(CGContextRef)context
{    
    // TODO concat custom transform?
    CGRect bounds = self.bounds;
    CGContextConcatCTM(context, (CGAffineTransform){
        self.contentsScale, 0,
        0, -self.contentsScale,
        bounds.origin.x, bounds.origin.y + bounds.size.height
    });
    CGContextTranslateCTM(context, 0, CGRectGetMaxY(bounds) - CGRectGetMaxY(self.CTFrameRect));
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CTFrameDraw(self.CTFrame, context);
    
//    CFArrayRef lines = CTFrameGetLines(self.CTFrame);
//    CFIndex lineCount = CFArrayGetCount(lines);
//    
//    CGFloat width, ascent, descent;
//    for (CFIndex lineIndex = 0; lineIndex < lineCount && lineIndex < 20; ++lineIndex) {
//        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
//        CTLineDraw(line, context);
//        
//        width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
//        
//        // note: context is in unknown state after ct draws, use save/reset
//        CGContextTranslateCTM(context, -width, ascent + descent);
//    }
}

- (void)layoutSublayers
{
    for (CALayer *layer in self.sublayers) {
        layer.frame = self.bounds;
    }
}

- (id<CAAction>)actionForKey:(NSString *)event
{
    // Removing every implicit animation
    return nil;
}

#pragma mark Public methods

- (void)setNeedsTextRendering
{
    if (CTFrame) 
    {
        CFRelease(CTFrame);
        CTFrame = NULL;
    }
    CTFrameRect = CGRectNull;
}

- (void)setFrame:(CGRect)frame autoAdjustToWrap:(BOOL)autoadjust
{
    wrapWidth = frame.size.width;
    if (autoadjust) 
    {
        [self setNeedsTextRendering];
        CGSize frameSize = frame.size;
        frameSize.height = ceilf(self.CTFrameRect.size.height);
        frame.size = frameSize;
    }
    [self setFrame:frame];
}

#pragma mark Private properties

- (CTFramesetterRef)CTFrameSetter
{
    if (string && (!CTFrameSetter || framesetterInvalid))
    {
        if (CTFrame)
        {
            CFRelease(CTFrame);
            CTFrame = NULL;
        }
        
        if (CTFrameSetter)
        {
            CFRelease(CTFrameSetter);
            CTFrameSetter = NULL;
        }
        
        CTFrameRect = CGRectNull;
        
        CTFrameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
        
        framesetterInvalid = NO;
    }
    return CTFrameSetter;
}

- (CTFrameRef)CTFrame
{
    if (!CTFrame || framesetterInvalid)
    {
        CGSize size = CGSizeMake(wrapped ? wrapWidth : 100000, 100000);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        CTFrame = CTFramesetterCreateFrame(self.CTFrameSetter, (CFRange){0, 0}, path, NULL);
        CGPathRelease(path);
    }
    
    return CTFrame;
}

- (CGRect)CTFrameRect
{
    if (CGRectIsNull(CTFrameRect) || framesetterInvalid)
    {
        CTFrameRect = ECCTFrameGetUsedRect(self.CTFrame, wrapped);
    }
    return CTFrameRect;
}

@end
