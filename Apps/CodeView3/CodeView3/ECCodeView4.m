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

#define TILEVIEWPOOL_SIZE (3)

#pragma mark -
#pragma mark TextTileView

@interface TextTileView : UIView {
@private
    ECTextRenderer *renderer;
}

@property (nonatomic) NSInteger tileIndex;

@property (nonatomic) UIEdgeInsets textInsets;

- (id)initWithTextRenderer:(ECTextRenderer *)aRenderer;

- (void)invalidate;

@end


@implementation TextTileView

@synthesize tileIndex, textInsets;

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
    
    // Drawing text
    CGContextSaveGState(context);
    {
        CGPoint textOffset = CGPointMake(0, rect.size.height * tileIndex);
        CGSize textSize = rect.size;
        if (tileIndex == 0) 
        {
            textSize.height -= textInsets.top;
            CGContextTranslateCTM(context, textInsets.left, textInsets.top);
        }
        else
        {
            textOffset.y -= textInsets.top;
            CGContextTranslateCTM(context, textInsets.left, 0);
        }
        CGRect textRect = (CGRect){ textOffset, rect.size };
        
        [renderer drawTextWithinRect:textRect inContext:context];
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

@interface ECCodeView4 () {
@private
    ECTextRenderer *renderer;
    
    TextTileView* tileViewPool[TILEVIEWPOOL_SIZE];
}

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex;

@end


@implementation ECCodeView4

#pragma mark Properties

@synthesize text, textInsets;

- (void)setTextDatasource:(id<ECTextRendererDatasource>)datasource
{
    if (datasource != self) 
    {
        [text release];
        text = nil;
    }
    renderer.datasource = datasource;
}

- (id<ECTextRendererDatasource>)textDatasource
{
    return renderer.datasource;
}

- (void)setTextInsets:(UIEdgeInsets)insets
{
    textInsets = insets;
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] setTextInsets:insets];
        [tileViewPool[i] setNeedsDisplay];
    }
}

- (void)setFrame:(CGRect)frame
{
    renderer.wrapWidth = UIEdgeInsetsInsetRect(frame, self->textInsets).size.width;
    self.contentSize = CGSizeMake(frame.size.width, renderer.estimatedHeight + textInsets.top + textInsets.bottom);
    
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, frame.size };
    }
    
    [super setFrame:frame];
}

- (void)setBackgroundColor:(UIColor *)color
{
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] setBackgroundColor:color];
        [tileViewPool[i] setNeedsDisplay];
    }
    [super setBackgroundColor:color];
}

#pragma mark NSObject Methods

static void preinit(ECCodeView4 *self)
{
    self->renderer = [ECTextRenderer new];
    self->renderer.lazyCaching = YES;
    self->renderer.preferredLineCountPerSegment = 500;
    self->renderer.datasource = self;
    
    self->textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

static void init(ECCodeView4 *self)
{
    
    self->renderer.wrapWidth = UIEdgeInsetsInsetRect(self.bounds, self->textInsets).size.width;
    [self->renderer addObserver:self forKeyPath:@"estimatedHeight" options:NSKeyValueObservingOptionNew context:nil];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == renderer) 
    {
        CGFloat height = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
        self.contentSize = CGSizeMake(self.bounds.size.width, height + textInsets.top + textInsets.bottom);
        return;
    }
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
        tileViewPool[selected].backgroundColor = self.backgroundColor;
        tileViewPool[selected].textInsets = textInsets;
        // TODO remove from self when not displayed
        [self addSubview:tileViewPool[selected]];
    }
    
    tileViewPool[selected].tileIndex = tileIndex;
    tileViewPool[selected].bounds = (CGRect){ CGPointZero, self.frame.size };
    [tileViewPool[selected] setNeedsDisplay];
    
    return tileViewPool[selected];
}

- (void)layoutSubviews
{
//    [super layoutSubviews];
    
    // Scrolled content rect
    CGRect contentRect = self.bounds;
    CGFloat halfHeight = contentRect.size.height / 2.0;
    
    // Find first visible tile index
    NSUInteger index = contentRect.origin.y / contentRect.size.height;
    
    // Layout first visible tile
    CGFloat firstTileEnd = (index + 1) * contentRect.size.height;
    TextTileView *firstTile = [self viewForTileIndex:index];
    [self sendSubviewToBack:firstTile];
    firstTile.hidden = NO;
    firstTile.center = CGPointMake(CGRectGetMidX(contentRect), firstTileEnd - halfHeight);
    
    // Layout second visible tile if needed
    if (firstTileEnd < CGRectGetMaxY(contentRect)) 
    {
        index++;
        TextTileView *secondTile = [self viewForTileIndex:index];
        [self sendSubviewToBack:secondTile];
        secondTile.hidden = NO;
        secondTile.center = CGPointMake(CGRectGetMidX(contentRect), firstTileEnd + halfHeight);
    }
}

#pragma mark -
#pragma mark Text Renderer String Datasource

- (void)setText:(NSAttributedString *)string
{
    if (self.textDatasource != self)
    {
        [NSException raise:NSInternalInconsistencyException format:@"Trying to set codeview text with textDelegate not self."];
        return;
    }
    
    // Set text
    [text release];
    text = [string retain];
    [renderer invalidateAllText];
        
    // Update tiles
    CGRect bounds = self.bounds;
    renderer.wrapWidth = UIEdgeInsetsInsetRect(bounds, self->textInsets).size.width;
    self.contentSize = CGSizeMake(bounds.size.width, renderer.estimatedHeight + textInsets.top + textInsets.bottom);
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, bounds.size };
    }
    
    [self setNeedsLayout];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange
{
    NSArray *lines = [[text string] componentsSeparatedByString:@"\n"];
    if (!lines || [lines count] == 0 || [lines count] <= (*lineRange).location)
        return nil;
    
    NSUInteger end = (*lineRange).length;
    if (end)
        end += (*lineRange).location;
    
    __block NSRange charRange = NSMakeRange(0, 0);
    __block NSUInteger lineCount = 0;
    [lines enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
        if (idx < (*lineRange).location) 
        {
            charRange.location += [str length] + 1;
        }
        else if (end == 0 || idx < end)
        {
            charRange.length += [str length] + 1;
            lineCount++;
        }
        else
        {
            *stop = YES;
        }
    }];
    charRange.length--;
    (*lineRange).length = lineCount;
    
    if (charRange.length == [text length]) 
    {
        return text;
    }
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

@end
