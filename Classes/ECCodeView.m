//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"


@implementation ECCodeView
@synthesize text;
@synthesize defaultParagraphStyle, defaultFont, defaultTextColor;

- (void)setText:(NSString *)aString
{
    if (aString != text)
    {
        [text release];
        text = [aString retain];
        // Create content string with default attributes
        if (!content || ![content length])
        {
            NSMutableDictionary *defaultAttributes = [NSMutableDictionary dictionary];
            if (defaultParagraphStyle)
                [defaultAttributes setObject:(id)defaultParagraphStyle forKey:(id)kCTParagraphStyleAttributeName];
            if (defaultCTFont)
                [defaultAttributes setObject:(id)defaultCTFont forKey:(id)kCTFontAttributeName];
            if (defaultTextColor)
                [defaultAttributes setObject:(id)[defaultTextColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
            content = [[NSMutableAttributedString alloc] initWithString:@"\n" attributes:defaultAttributes];
        }
        // TODO call before mutate
        NSInteger len = [content length];
        if (text)
        {
            [content replaceCharactersInRange:(NSRange){0, len - 1} withString:text];
            len = [content length];
            if (len > 1)
                [content setAttributes:[content attributesAtIndex:len - 2 effectiveRange:NULL] range:(NSRange){len - 1, 1}];
        }
        else
        {
            if (len > 1)
                [content deleteCharactersInRange:(NSRange){0, len - 1}];
        }
        // TODO call after mutate
//        [self unmarkText];
        // TODO set selection to end
        // TODO call delegate's textdidcahnge
        [self setNeedsDisplay];
    }
}

- (void)setDefaultFont:(UIFont *)aFont
{
    if (defaultFont != aFont)
    {
        [defaultFont release];
        defaultFont = [aFont retain];
        if (defaultCTFont)
        {
            CFRelease(defaultCTFont);
        }
        defaultCTFont = CTFontCreateWithName((CFStringRef)defaultFont.fontName, defaultFont.pointSize, &CGAffineTransformIdentity);
    }
}

#pragma mark Initializations

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    { 
        self.contentInset = UIEdgeInsetsMake(10, 10, 0, 0);
        self.defaultFont = [UIFont fontWithName:@"Courier New" size:12];
        self.text = @"int main(arguments)\n{\n\treturn 0;\n}";
        
        [super setContentMode:UIViewContentModeRedraw];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) 
    {
        [self init];
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
    UIEdgeInsets inset = self.contentInset;
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
        contentFrameOrigin = CGPointMake(inset.left, -inset.top);
        
        // TODO call delegate layoutChanged
    }
    // TODO to here: _updateLayout
    
    // TODO draw selection
    
    // Transform to flipped rendering space
    CGFloat scale = self.zoomScale;
    CGContextConcatCTM(context, (CGAffineTransform){
        scale, 0,
        0, -scale,
        bounds.origin.x, bounds.origin.y + bounds.size.height
    });    
    
    // Draw core text frame
    // TODO! clip on rect
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, contentFrameOrigin.x, contentFrameOrigin.y);
    CTFrameDraw(contentFrame, context);
    CGContextTranslateCTM(context, -contentFrameOrigin.x, -contentFrameOrigin.y);
    
    // TODO draw decorations
    
    [super drawRect:rect];
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

//- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
//{	
//	if (!self.dragging) 
//    {
//		[self.nextResponder touchesEnded:touches withEvent:event]; 
//	}
//	[super touchesEnded:touches withEvent:event];
//}

#pragma mark Code view methods

- (void)addErrorAtRange:(UITextRange*)range
{
    
}

@end
