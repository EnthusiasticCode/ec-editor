//
//  ECLineMarks.m
//  edit
//
//  Created by Nicola Peduzzi on 01/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECLineMarksView.h"


@implementation ECLineMarksView

@dynamic delegate;
@synthesize drawMarkBlock, markSize, markInsets, lineCount;

static inline id init(ECLineMarksView *self)
{
    [self setOpaque:NO];
    self->marks = [[NSMutableDictionary alloc] init];
    self->markSize = CGSizeMake(7, 3);
    self->markInsets = UIEdgeInsetsMake(5, 1, 5, 1);
    self->drawMarkBlock = ^(CGContextRef ctx, CGRect rct, UIColor *clr) {
        [[clr colorWithAlphaComponent:0.4] setFill];
        CGContextFillRect(ctx, rct);
    };
    return self;
}

#pragma mark -
#pragma mark UIView methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    [marks release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    
    // Draw marks
    if (lineCount > 0)
    {
        CGFloat lineStep = (bounds.size.height - markInsets.top - markInsets.bottom ) / lineCount;
        CGPoint markPoint = CGPointMake(bounds.origin.x + bounds.size.width - markSize.width - markInsets.right, markInsets.top);
        [marks enumerateKeysAndObjectsUsingBlock:^(id color, id lines, BOOL *stop) {
            [(NSMutableIndexSet *)lines enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                if (idx < lineCount)
                {
                    CGRect markRect = (CGRect){ {markPoint.x, markPoint.y + lineStep * idx}, markSize };
                    drawMarkBlock(context, markRect, color);
                }
            }];
        }];
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size.width = markInsets.left + markInsets.right + markSize.width;
    return size;
}

#pragma mark -
#pragma mark Marks API methods

- (void)setMarkSize:(CGSize)size
{
    markSize = size;
    if ([marks count] > 0)
        [self setNeedsDisplay];
}

- (void)setLineCount:(NSUInteger)count
{
    if (count != lineCount)
    {
        lineCount = count;
        if ([marks count] > 0)
            [self setNeedsDisplay];
    }
}

- (void)addMarksWithColor:(UIColor *)color forLines:(NSIndexSet *)lines
{
    NSMutableIndexSet *indexes = [marks objectForKey:color];
    if (!indexes)
    {
        indexes = [NSMutableIndexSet indexSet];
        [marks setObject:indexes forKey:color];
    }
    [indexes addIndexes:lines];
    [self setNeedsDisplay];
}

- (void)removeAllMarks
{
    [marks removeAllObjects];
    [self setNeedsDisplay];
}

- (void)removaAllMarksWithColor:(UIColor *)color
{
    [marks removeObjectForKey:color];
    [self setNeedsDisplay];
}

@end
