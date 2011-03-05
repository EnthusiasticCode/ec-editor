//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"
#import "ECTextLayer.h"


@interface ECCodeView () {
@protected
    NSMutableAttributedString *text;
    
@private
    ECTextLayer *textLayer;
}

/// Return the length of the text, use this method instead of [text length] to maintain compatibility.
@property (nonatomic, readonly) NSUInteger textLength;

@end

@implementation ECCodeView

#pragma mark Properties

@synthesize defaultTextStyle;

- (void)setText:(NSString *)string
{
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

#pragma mark -
#pragma mark UIView methods

static inline id init(ECCodeView *self)
{
    // Setup view's layer
    self.opaque = YES;
    self.layer.cornerRadius = 20;
    self.layer.masksToBounds = YES;
    //    self.clearsContextBeforeDrawing = YES;
    //    self.contentMode = UIViewContentModeRedraw;
    
    // Text layer
    self->textLayer = [ECTextLayer layer];
    self->textLayer.opaque = YES;
    self->textLayer.backgroundColor = self.backgroundColor.CGColor;
    self->textLayer.wrapped = YES;
    self->textLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:self->textLayer];
    
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
    [super dealloc];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    textLayer.backgroundColor = backgroundColor.CGColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Layout sublayers
    CGRect textLayerFrame = self.layer.bounds;
    textLayerFrame = CGRectInset(textLayerFrame, 20, 20);
    textLayerFrame.size = [textLayer sizeThatFits:textLayerFrame.size];
    textLayer.frame = (textLayerFrame);
}

#pragma mark -
#pragma mark ECCodeView text style methods

- (void)setTextStyle:(ECTextStyle *)style toTextRange:(ECTextRange *)range
{
    if (range && ![range isEmpty] && style)
    {
        NSUInteger textLength = [self textLength];
        NSUInteger s = ((ECTextPosition *)range.start).index;
        NSUInteger e = MIN(((ECTextPosition *)range.end).index, textLength);
        if (s < e)
        {
            [text setAttributes:style.CTAttributes range:(NSRange){s, e - s}];
            [textLayer invalidateContent];
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
        e = MIN(((ECTextPosition *)range.end).index, textLength);
        if (s < e)
        {
            [text setAttributes:((ECTextStyle *)[styles objectAtIndex:i]).CTAttributes range:(NSRange){s, e - s}];
        }
    }
    
    [textLayer invalidateContent];
}

#pragma mark -
#pragma mark Private properties

- (NSUInteger)textLength
{
    return [text length];
}

@end
