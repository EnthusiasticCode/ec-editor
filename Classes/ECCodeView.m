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

- (void)setText:(NSString *)string
{
    if (!text)
    {
        // TODO extract createText method
        text = [[NSMutableAttributedString alloc] init];
        textLayer.string = text;
    }
    
    NSUInteger textLength = [self textLength];
    if (string)
    {
        [text replaceCharactersInRange:(NSRange){0, textLength} withString:string];
    }
    else if (textLength > 0)
    {
        [text deleteCharactersInRange:(NSRange){0, textLength}];
    }
    
    [textLayer invalidateContent];
}

- (NSString *)text
{
    return [[text string] substringToIndex:[self textLength]];
}

#pragma mark UIView methods

static inline id init(ECCodeView *self)
{
    // Text layer
    self->textLayer = [ECTextLayer layer];
    self->textLayer.backgroundColor = self.backgroundColor.CGColor;
    self->textLayer.wrapped = YES;
    self->textLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:self->textLayer];
    
//    self->textLayer.backgroundColor = [UIColor orangeColor].CGColor; 
    
//    self.clearsContextBeforeDrawing = YES;
//    self.contentMode = UIViewContentModeRedraw;
    
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
    textLayerFrame.size = [textLayer sizeThatFits:textLayerFrame.size];
    textLayer.frame = textLayerFrame;
}

#pragma mark Private properties

- (NSUInteger)textLength
{
    return [text length];
}

@end
