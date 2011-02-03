//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"
#import "ECTextPosition.h"

const NSString* ECCodeStyleDefaultTextName = @"Default";
const NSString* ECCodeStyleKeywordName = @"Keyword";
const NSString* ECCodeStyleCommentName = @"Comment";

@interface ECCodeView ()

// This method is used to indicate that the content has changed and the 
// rendering frame generated from it should be recalculated.
- (void)setNeedsContentFrame;

@end

@implementation ECCodeView

#pragma mark Properties

@synthesize text;
- (void)setText:(NSString *)aString
{
    if (aString != text)
    {
        [text release];
        text = [aString retain];
        // Create content string with default attributes
        // A tailing new line will be kept to have a reference on used attributes
        // and possibly a non empty rect when rendering.
        if (!content || ![content length])
        {
            content = [[NSMutableAttributedString alloc] init];
        }
        // TODO call before mutate
        NSInteger len = [content length];
        if (text)
        {
            [content replaceCharactersInRange:(NSRange){0, len} withString:text];
            len = [content length];
            if (len > 1)
                [content setAttributes:defaultAttributes range:(NSRange){0, len}];
        }
        else
        {
            if (len > 1)
                [content deleteCharactersInRange:(NSRange){0, len}];
        }
        // TODO call after mutate
        //        [self unmarkText];
        // TODO set selection to end
        // TODO call delegate's textdidcahnge
        [self setNeedsContentFrame];
        [self setNeedsDisplay];
    }
}

@synthesize styles = _styles;
- (void)setStyles:(NSDictionary*)aDictionary
{
    [_styles release];
    _styles = [aDictionary mutableCopy];
    // TODO check that every style's attributes contains style backref
    NSDictionary *def = [aDictionary objectForKey:ECCodeStyleDefaultTextName];
    if (def)
    {
        [defaultAttributes release];
        defaultAttributes = [def retain];
        // TODO setup background color?
    }
    // TODO reset attributes in string
    [self setNeedsDisplay];
}

#pragma mark CodeView Initializations

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    { 
        CTFontRef defaultFont = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
        defaultAttributes = [[NSDictionary dictionaryWithObject:(id)defaultFont forKey:(id)kCTFontAttributeName] retain];
        // TODO set full default coloring if textSyles == nil
        _styles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:defaultAttributes, ECCodeStyleDefaultTextName, nil];
        
        self.contentInset = UIEdgeInsetsMake(10, 10, 0, 0);
        
        [super setContentMode:UIViewContentModeRedraw];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) 
    {
        // TODO call a do_init instead?
        [self init];
    }
    return self;
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
    self.styles = nil;
    [defaultAttributes release];
    [super dealloc];
}

#pragma mark UIView override

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

//- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
//{	
//	if (!self.dragging) 
//    {
//		[self.nextResponder touchesEnded:touches withEvent:event]; 
//	}
//	[super touchesEnded:touches withEvent:event];
//}

#pragma mark CodeView methods

// see setValue:forAttribute:inRange
- (void)setStyleNamed:(const NSString*)aStyle toRange:(NSRange)range
{
    // Get attribute dictionary
    NSDictionary *attributes = [_styles objectForKey:aStyle];
    if (attributes == nil)
        attributes = defaultAttributes;
    // TODO setSolidCaret
    // TODO call beforeMutate
    NSUInteger contentLength = [content length];
    NSRange crange = [[content string] rangeOfComposedCharacterSequencesForRange:range];
    if (crange.location + crange.length > contentLength)
        crange.length = (contentLength - crange.location);
    [content setAttributes:attributes range:crange];
    // TODO call after_mutate
    [self setNeedsContentFrame];
    [self setNeedsDisplay];
}

#pragma mark CodeViewUtilities

- (void)setAttributes:(NSDictionary*)attributes forStyleNamed:(const NSString*)aStyle
{
    [_styles setObject:attributes forKey:aStyle];
    // TODO update every content part with this style
    //    [self setNeedsContentFrame];
    //    [self setNeedsDisplay];
}

#pragma mark CodeView private methods

// TODO rethink: contentFrameInvalid should be YES if text/attr changed to recreate framesetter, 
// contentFrame should be released and set to nil when bounds changes.
- (void)setNeedsContentFrame
{
    contentFrameInvalid = YES;
    
    // TODO any content sanity check? see _didChangeContent
}

@end
