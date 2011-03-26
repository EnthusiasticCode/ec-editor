//
//  ECTextLayer.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextLayer.h"

@interface ECTextLayer () {
@private
    BOOL CTFrameInvalid;
}

@property (nonatomic, readonly) CTFramesetterRef CTFrameSetter;

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
    [self setNeedsCTFrameRendering];
}


#pragma mark CALayer methods

- (void)setBounds:(CGRect)bounds
{
    CTFrameInvalid = YES;
    [super setBounds:bounds];
}

- (BOOL)isGeometryFlipped
{
    return YES;
}

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

    // TODO concat custom transform?
    CGContextConcatCTM(context, (CGAffineTransform){
        self.contentsScale, 0,
        0, -self.contentsScale,
        0, self.CTFrameSize.height
    });
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CTFrameDraw(self.CTFrame, context);
}

- (void)layoutSublayers
{
    for (CALayer *layer in self.sublayers) {
        layer.frame = self.bounds;
    }
}

- (id<CAAction>)actionForKey:(NSString *)event
{
    return nil;
}

#pragma mark Public methods

- (void)setNeedsCTFrameRendering
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
    // TODO Fix this fix
    size.height += 2;
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
    if (!CTFrame || CTFrameInvalid)
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
    if (CGSizeEqualToSize(CTFrameSize, CGSizeZero) || CTFrameInvalid)
    {
        CTFrameSize = [self sizeThatFits:self.bounds.size];
    }
    return CTFrameSize;
}

@end
