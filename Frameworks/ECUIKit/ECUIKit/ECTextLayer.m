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

- (void)setBounds:(CGRect)bounds
{
    if (!CGRectEqualToRect(bounds, self.bounds)) 
    {
        [super setBounds:bounds];
        [self setNeedsTextRendering];
    }
}

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
    CGRect bounds = self.bounds;
    CGContextConcatCTM(context, (CGAffineTransform){
        1, 0,
        0, -1,
        bounds.origin.x, bounds.origin.y + bounds.size.height
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

- (CGSize)sizeThatFits:(CGSize)size
{
    if (!wrapped) {
        size.width = CGFLOAT_MAX;
    }
    size.height = CGFLOAT_MAX;
    
    CFRange fitRange;
    size = CTFramesetterSuggestFrameSizeWithConstraints(self.CTFrameSetter, (CFRange){0, 0}, NULL, size, &fitRange);
    
    // Fix this fix
    size.height += 1;
    
    size.height = ceilf(size.height);
    size.width = ceilf(size.width);
    
    return size;
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
        CGSize size = self.bounds.size;
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
