//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"
#import "ECTextOverlayLayer.h"


@interface ECCodeView () {    
@private
    NSMutableDictionary *overlayLayers;
}

@end

@implementation ECCodeView

#pragma mark Properties

@synthesize defaultTextStyle;

- (void)setText:(NSString *)string
{
    [self clearAllTextOverlays];
    [text release];
    if (!string)
        string = @"";
    text = [[NSMutableAttributedString alloc] initWithString:string attributes:self.defaultTextStyle.CTAttributes];
    textLayer.string = text;
}

- (NSString *)text
{
    return [[text string] substringToIndex:[self textLength]];
}

- (NSUInteger)textLength
{
    return [text length];
}

#pragma mark -
#pragma mark Public methods
- (void)setNeedsTextRendering
{
    [textLayer setNeedsCTFrameRendering];
}


#pragma mark -
#pragma mark UIView methods

static inline id init(ECCodeView *self)
{
    // Setup view's layer
    self.opaque = YES;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    //    self.clearsContextBeforeDrawing = YES;
    //    self.contentMode = UIViewContentModeRedraw;
    
    // Text layer
    self->textLayer = [ECTextLayer layer];
    self->textLayer.opaque = NO;
    self->textLayer.wrapped = YES;
    self->textLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:self->textLayer];
    
    // Overlay layers
    self->overlayLayers = [[NSMutableDictionary dictionaryWithCapacity:3] retain];
    
    // Default styling
    self.defaultTextStyle = [ECTextStyle textStyleWithName:@"Plain text" font:[UIFont fontWithName:@"Courier New" size:16.0] color:[UIColor blackColor]];
    
    // Trigger text creation
    self.text = nil;
    
    [self setNeedsDisplay];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
    if ((self = [super initWithCoder:coder])) 
    {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    [text release];
    [overlayLayers release];
    [super dealloc];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    textLayer.backgroundColor = backgroundColor.CGColor;
}

- (void)layoutSubviews
{
//    [super layoutSubviews];
    
    // Layout text layer
    CGRect textLayerFrame = self.bounds;
    textLayerFrame = CGRectInset(textLayerFrame, 10, 10);
    textLayerFrame.size = [textLayer sizeThatFits:textLayerFrame.size];
    textLayerFrame = CGRectIntegral(textLayerFrame);
    textLayer.frame = textLayerFrame;
    
    // Layout text overlay layers
    [overlayLayers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(CALayer *)obj setFrame:textLayerFrame];
    }];
}

#pragma mark -
#pragma mark ECCodeView text style methods

- (void)setTextStyle:(ECTextStyle *)style toTextRange:(ECTextRange *)range
{
    if (range && ![range isEmpty] && style)
    {
        NSUInteger textLength = [self textLength];
        NSUInteger s = ((ECTextPosition *)range.start).index;
        NSUInteger e = ((ECTextPosition *)range.end).index;
        if (e > textLength)
            e = textLength;
        if (s < e)
        {
            [text setAttributes:style.CTAttributes range:(NSRange){s, e - s}];
            [textLayer setNeedsCTFrameRendering];
        }
    }
}

- (void)setTextStyles:(NSArray *)styles toTextRanges:(NSArray *)ranges
{
    NSUInteger count = [styles count];
    if (count != [ranges count])
    {
        return;
    }
    
    NSUInteger textLength = [self textLength];
    ECTextRange *range;
    NSUInteger s, e;
    for (NSUInteger i = 0; i < count; ++i)
    {
        range = (ECTextRange *)[ranges objectAtIndex:i];
        s = ((ECTextPosition *)range.start).index;
        e = ((ECTextPosition *)range.end).index;
        if (e > textLength)
            e = textLength;
        if (s < e)
        {
            [text setAttributes:((ECTextStyle *)[styles objectAtIndex:i]).CTAttributes range:(NSRange){s, e - s}];
        }
    }
    
    [textLayer setNeedsCTFrameRendering];
}

#pragma mark -
#pragma mark ECCodeView text overlay methods

// TODO instead of one layer per style, layers should be created as a shared resource and used by a style if 
// hidden/empty. This way a style could apply different animations to specific instances of overlay to a range.
- (void)addTextOverlayWithStyle:(ECTextOverlayStyle *)style 
               forTextRange:(ECTextRange *)range 
{
    if (!style || !range)
        return;
    
    ECTextOverlayLayer *overlayLayer = [overlayLayers objectForKey:style.name];
    
    if (!overlayLayer)
    {
        overlayLayer = [[ECTextOverlayLayer alloc] initWithTextOverlayStyle:style];
//        overlayLayer.needsDisplayOnBoundsChange = YES;
        [overlayLayers setObject:overlayLayer forKey:style.name];
        if (style.isBelowText)
        {
            [self.layer insertSublayer:overlayLayer below:textLayer];
        }
        else 
        {
            [self.layer addSublayer:overlayLayer];
        }
        [overlayLayer release];
    }
    
    NSRange r = [range range];
    ECMutableRectSet *rs = [ECMutableRectSet rectSet];
    ECCTFrameProcessRectsOfLinesInStringRange(textLayer.CTFrame, CFRangeMake(r.location, r.length), ^(CGRect rect) {
        [rs addRect:rect];
    });
    
    NSMutableArray *rects = [overlayLayer.overlayRectSets mutableCopy];
    [rects addObject:rs];
    overlayLayer.overlayRectSets = rects;
}

- (void)clearTextOverlayWithStyle:(ECTextOverlayStyle *)style
{
    CALayer *overlayLayer = [overlayLayers objectForKey:style.name];
    if (overlayLayer)
    {
        [overlayLayer removeFromSuperlayer];
        [overlayLayers removeObjectForKey:style.name];
    }
}

- (void)clearAllTextOverlays
{
    [overlayLayers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [obj removeFromSuperlayer];
    }];
    [overlayLayers removeAllObjects];
}

#pragma mark -
#pragma mark Private properties


@end
