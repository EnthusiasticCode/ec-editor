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


#pragma mark -
#pragma mark TextTileView

@interface TextTileView : UIView

@property (nonatomic) NSUInteger tileIndex;

@property (getter = isDirty) BOOL dirty;

@end

@implementation TextTileView

@synthesize tileIndex, dirty;

@end

#pragma mark -
#pragma mark ECCodeView4

#define TILEPOOL_COUNT (3)

@interface ECCodeView4 () {
@private
    ECMutableTextFileRenderer *renderer;
    
    TextTileView* tilePool[TILEPOOL_COUNT];
    CGSize *tileSizes;
}

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex;

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
    
    self.contentSize = [renderer renderedSizeForTextRect:CGRectNull allowGuessedResult:YES];
    
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

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex
{
    int selected = 0;
    //
    for (int i = 0; i < TILEPOOL_COUNT; ++i) 
    {
        if (tilePool[i] && [tilePool[i] tileIndex] == tileIndex)
        {
            return tilePool[i];
        }
        selected = i;
    }
    // Generate new tile
    if (tilePool[selected] == nil)
    {
        tilePool[selected] = [TextTileView new];
        [tilePool[selected] setTileIndex:tileIndex];
    }
    
    return tilePool[selected];
}

- (void)layoutSubviews
{
    if (!tileSizes)
        return;
}

@end
