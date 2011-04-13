//
//  ECCodeView4.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView4.h"
#import <QuartzCore/QuartzCore.h>
#import "ECMutableTextFileRenderer.h"

@interface TextTileView : UIView 
@end


#define TILES_COUNT (3)

@interface ECCodeView4 () {
@private
    ECMutableTextFileRenderer *renderer;
    
    TextTileView* tiles[TILES_COUNT];
}
@end

@implementation ECCodeView4

#pragma mark -
#pragma mark Properties

@synthesize text, textInsets;

- (void)setText:(NSAttributedString *)string
{
    [text release];
    text = [string retain];
    [renderer setString:text];
    
    self.contentSize = [renderer renderedTextSizeAllowGuessedResult:YES];
    
    [self setNeedsDisplay];
}

- (void)setBounds:(CGRect)bounds
{
    [(CATiledLayer *)self.layer setTileSize:bounds.size];
    [super setBounds:bounds];
}

- (void)setFrame:(CGRect)frame
{
    [(CATiledLayer *)self.layer setTileSize:frame.size];
    [super setFrame:frame];
}

#pragma mark -
#pragma mark NSObject Methods

static void preinit(ECCodeView4 *self)
{
    self->textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

static void init(ECCodeView4 *self)
{
    self->renderer = [ECMutableTextFileRenderer new];
    self->renderer.frameWidth = UIEdgeInsetsInsetRect(self.bounds, self->textInsets).size.width;
    self->renderer.framePreferredHeight = self.bounds.size.height;
}

- (id)initWithFrame:(CGRect)frame
{
    preinit(self);
    self = [super initWithFrame:frame];
    if (self) {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
    preinit(self);
    self = [super initWithCoder:coder];
    if (self) {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    [renderer release];
    [super dealloc];
}

#pragma mark -
#pragma mark Rendering Methods

- (void)layoutSubviews
{
    
}

@end
