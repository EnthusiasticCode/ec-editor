//
//  ECCodeView4.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView4.h"
#import <QuartzCore/QuartzCore.h>
#import "ECTextRenderer.h"


#pragma mark -
#pragma mark TextTileView

@interface TextTileView : UIView {
@private
    ECTextRenderer *renderer;
}

- (id)initWithTextRenderer:(ECTextRenderer *)aRenderer;

@property (nonatomic) NSInteger tileIndex;

- (void)invalidate;

@end

@implementation TextTileView

@synthesize tileIndex;

- (id)initWithTextRenderer:(ECTextRenderer *)aRenderer
{
    if ((self = [super init]))
    {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        renderer = aRenderer;
    }
    return self;
}

- (void)invalidate
{
    tileIndex = -2;
    self.hidden = YES;
}

- (void)drawRect:(CGRect)rect
{
    if (tileIndex < 0)
        return;
    
    // TODO draw "transparent" bg and thatn draw text in deferred queue
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.backgroundColor setFill];
    CGContextFillRect(context, rect);
    
    CGContextSaveGState(context);
    {
        CGPoint textOffset = CGPointMake(0, rect.size.height * tileIndex);
        [renderer drawTextWithinRect:(CGRect){ textOffset, rect.size } inContext:context];
    }
    CGContextRestoreGState(context);
    
    // DEBUG
    [[UIColor redColor] setStroke];
    CGContextSetLineWidth(context, 2);
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, 10, rect.size.height);
    CGContextStrokePath(context);
}

@end

#pragma mark -
#pragma mark ECCodeView4

#define TILEVIEWPOOL_SIZE (3)

@interface ECCodeView4 () {
@private
    ECTextRenderer *renderer;
    
    TextTileView* tileViewPool[TILEVIEWPOOL_SIZE];
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
    [renderer invalidateAllText];
    
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
    }
    
    [self setNeedsLayout];
}

- (void)setFrame:(CGRect)frame
{
    if (text) 
    {
        renderer.wrapWidth = UIEdgeInsetsInsetRect(frame, self->textInsets).size.width;
        CGRect renderRect = [renderer rectForIntegralNumberOfTextLinesWithinRect:CGRectInfinite allowGuessedResult:YES];
        renderRect.size.width = frame.size.width;
        self.contentSize = renderRect.size;
        
        for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
        {
            [tileViewPool[i] invalidate];
            tileViewPool[i].bounds = (CGRect){ CGPointZero, frame.size };
        }
    }
    
    [super setFrame:frame];
//    [self setNeedsLayout];
}

#pragma mark -
#pragma mark DEBUG Text Renderer Datasource

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender 
                   stringInLineRange:(NSRange *)lineRange
{
    NSArray *lines = [[text string] componentsSeparatedByString:@"\n"];
    NSUInteger end = (*lineRange).location + (*lineRange).length;

    __block NSRange charRange = NSMakeRange(0, 0);
    [lines enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
        if (idx < (*lineRange).location) 
        {
            charRange.location += [str length] + 1;
        }
        else if (idx < end)
        {
            charRange.length += [str length] + 1;
        }
        else
        {
            *stop = YES;
        }
    }];
    
    if (charRange.length == [text length]) 
    {
        return text;
    }
    charRange.length--;
    return [text attributedSubstringFromRange:charRange];
}

- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength
{
    NSArray *lines = [[text string] componentsSeparatedByString:@"\n"];
    
    __block NSUInteger lineCount = 0;
    [lines enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
        lineCount += ([str length] / maximumLineLength) + 1;
    }];
    
    return lineCount;
}

#pragma mark -
#pragma mark NSObject Methods

static void preinit(ECCodeView4 *self)
{
    self->textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

static void init(ECCodeView4 *self)
{
    self->renderer = [ECTextRenderer new];
    self->renderer.wrapWidth = UIEdgeInsetsInsetRect(self.bounds, self->textInsets).size.width;
    self->renderer.lazyCaching = YES;
    self->renderer.datasource = self;
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
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
        [tileViewPool[i] release];
    [renderer release];
    [super dealloc];
}

#pragma mark -
#pragma mark Rendering Methods

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex
{
    NSInteger selected = -1;
    // Select free tile
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i) 
    {
        if (tileViewPool[i])
        {
            // Tile already present and ready
            if ([tileViewPool[i] tileIndex] == tileIndex)
            {
                return tileViewPool[i];
            }
            // If still no selection just select this as a candidate
            if (selected >= 0)
                continue;
            // Select only if better than previous
            if (abs([tileViewPool[i] tileIndex] - tileIndex) <= 1) 
                continue;
        }
        selected = i;
    }
    
    // Generate new tile
    if (!tileViewPool[selected]) 
    {
        tileViewPool[selected] = [[TextTileView alloc] initWithTextRenderer:renderer];
        // TODO remove from self when not displayed
        [self addSubview:tileViewPool[selected]];
    }
    
    tileViewPool[selected].tileIndex = tileIndex;
    
    return tileViewPool[selected];
}

- (void)layoutSubviews
{
//    [super layoutSubviews];
    
    // Scrolled content rect
    CGRect contentRect = self.bounds;
    
    // Find first visible tile index
    NSUInteger index = contentRect.origin.y / contentRect.size.height;
    
    // Layout first visible tile
    CGFloat firstTileEnd = (index + 1) * contentRect.size.height;
    TextTileView *firstTile = [self viewForTileIndex:index];
    [self sendSubviewToBack:firstTile];
    firstTile.hidden = NO;
    firstTile.center = CGPointMake(CGRectGetMidX(contentRect), firstTileEnd / 2.0);
    
    // Layout second visible tile if needed
    if (firstTileEnd < CGRectGetMaxY(contentRect)) 
    {
        index++;
        TextTileView *secondTile = [self viewForTileIndex:index];
        [self sendSubviewToBack:secondTile];
        secondTile.hidden = NO;
        secondTile.center = CGPointMake(CGRectGetMidX(contentRect), ((index + 1) * contentRect.size.height) / 2.0);
    }
}

@end
