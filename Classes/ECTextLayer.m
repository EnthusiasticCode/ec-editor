//
//  ECTextLayer.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextLayer.h"
#import <CoreText/CoreText.h>

@interface ECTextLayer () {
@private
    BOOL CTFrameInvalid;
}

@property (nonatomic, readonly) CTFramesetterRef CTFrameSetter;
@property (nonatomic, readonly) CTFrameRef CTFrame;
@property (nonatomic, readonly) CGSize CTFrameSize;

@end

#pragma mark -

@implementation ECTextLayer

#pragma mark Properties

@synthesize string;
@synthesize wrapped;

- (CFArrayRef)CTLines
{
    return CTFrameGetLines(self.CTFrame);
}

- (void)setString:(NSAttributedString *)aString
{
    string = aString;
    [self invalidateContent];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:CGRectIntegral(bounds)];
    if (wrapped)
        [self invalidateContent];
}

#pragma mark CALayer methods

- (CGSize)preferredFrameSize
{
    CGRect bounds = self.bounds;
    bounds.size = self.CTFrameSize;
    bounds = [self.superlayer convertRect:bounds fromLayer:self];
    return bounds.size;
}

 - (void)drawInContext:(CGContextRef)context
{
    CGContextSetFillColorWithColor(context, self.backgroundColor);
    CGContextFillRect(context, self.bounds);

    CGContextConcatCTM(context, (CGAffineTransform){
        self.contentsScale, 0,
        0, -self.contentsScale,
        0, self.CTFrameSize.height
    });
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CTFrameDraw(self.CTFrame, context);
}

#pragma mark Public methods

- (void)invalidateContent
{
    CTFrameInvalid = YES;
    [self setNeedsDisplay];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CFRange fitRange;
    size.height = CGFLOAT_MAX;
    if (!wrapped)
    {
        size.width = CGFLOAT_MAX;
    }
    size = CTFramesetterSuggestFrameSizeWithConstraints(self.CTFrameSetter, (CFRange){0, 0}, NULL, size, &fitRange);
    return size;
}

#pragma mark Private properties

@synthesize CTFrameSetter;
@synthesize CTFrame;
@synthesize CTFrameSize;

- (CTFramesetterRef)CTFrameSetter
{
    if (string && (!CTFrameSetter || CTFrameInvalid))
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
        
        CTFrameSize = CGSizeZero;
        
        CTFrameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
        
        CTFrameInvalid = NO;
    }
    return CTFrameSetter;
}

- (CTFrameRef)CTFrame
{
    if (!CTFrame && CTFrameSetter)
    {
        CGSize size = self.CTFrameSize;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        CTFrame = CTFramesetterCreateFrame(self.CTFrameSetter, (CFRange){0, 0}, path, NULL);
        CGPathRelease(path);
    }
    
    return CTFrame;
}

- (CGSize)CTFrameSize
{
    if (CGSizeEqualToSize(CTFrameSize, CGSizeZero))
    {
        CTFrameSize = [self sizeThatFits:self.bounds.size];
    }
    return CTFrameSize;
}

@end
