//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"


@implementation ECCodeView
@synthesize textInset;

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
        CTFontRef font = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)font forKey:(id)kCTFontAttributeName];
        
        content = [[NSMutableAttributedString alloc] initWithString:@"int main(arguments)\n{\n\treturn 0;\n}\n" attributes:attributes];
        
        CFRelease(font);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        CTFontRef font = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)font forKey:(id)kCTFontAttributeName];
        
        content = [[NSMutableAttributedString alloc] initWithString:@"int main(arguments)\n{\n\treturn 0;\n}\n" attributes:attributes];
        
        CFRelease(font);
        
        textInset = UIEdgeInsetsMake(10, 10, 0, 0);
    }
    return self;
}


- (void)drawRect:(CGRect)rect 
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    
    // background
    UIColor *background = self.backgroundColor;
    if (background)
    {
        [background setFill];
        CGContextFillRect(context, rect);
    }
    
    // TODO from here: _updateLayout
    // Generate framesetter
    if (!frameSetter || contentFrameInvalid)
    {
        if (contentFrame)
        {
            CFRelease(contentFrame);
            contentFrame = NULL;
        }
        if (frameSetter)
        {
            CFRelease(frameSetter);
            frameSetter = NULL;
        }
        // TODO instead of using cache use lock?
        frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)content);
        contentFrameInvalid = NO;
    }
    
    // Render core text content frame
    while (!contentFrame)
    {
        // Setup rendering path
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, bounds.size.width, bounds.size.height));
        contentFrame = CTFramesetterCreateFrame(frameSetter, (CFRange){0, 0}, path, NULL);
        CFRelease(path);
        
        // TODO? Calculate effective size
        //CFRange fitRange;
        //CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, (CFRange){0, 0}, NULL, bounds.size, &fitRange);
        
        // TODO? Calculating the rendering coordinate position of the text layout origin
        contentFrameOrigin = CGPointMake(textInset.left, -textInset.top);
        
        // TODO call delegate layoutChanged
    }
    // TODO to here: _updateLayout
    
    // TODO draw selection
    
    // Transform to flipped rendering space
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Draw core text frame
    // TODO! clip on rect
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, contentFrameOrigin.x, contentFrameOrigin.y);
    CTFrameDraw(contentFrame, context);
    CGContextTranslateCTM(context, -contentFrameOrigin.x, -contentFrameOrigin.y);
    
    // TODO draw decorations
}


- (void)dealloc 
{
    [content release];
    if (contentFrame)
    {
        CFRelease(contentFrame);
    }
    if (frameSetter)
    {
        CFRelease(frameSetter);
    }
    [super dealloc];
}


@end
