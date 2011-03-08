//
//  ECLineMarks.m
//  edit
//
//  Created by Nicola Peduzzi on 01/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECLineMarksView.h"

@interface ECLineMarksView ()

- (void)markTapped:(UITapGestureRecognizer *)recognizer;

@end

@implementation ECLineMarksView

@synthesize delegate, drawMarkBlock, markSize, markInsets, lineCount;

static inline id init(ECLineMarksView *self)
{
    [self setOpaque:NO];
    self->marks = [[NSMutableDictionary alloc] init];
    self->markSize = CGSizeMake(7, 3);
    self->markInsets = UIEdgeInsetsMake(10, 1, 10, 1);
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

- (void)didMoveToWindow
{
    if (!tapMarkRecognizer)
    {
        tapMarkRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(markTapped:)];
        [self addGestureRecognizer:tapMarkRecognizer];
        tapMarkRecognizer.enabled = [marks count] > 0;
    }
}

- (void)dealloc
{
    [tapMarkRecognizer release];
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
            [(NSMutableIndexSet *)lines enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *istop) {
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
    if ([lines count] == 0)
        return;
    NSMutableIndexSet *indexes = [marks objectForKey:color];
    if (!indexes)
    {
        indexes = [NSMutableIndexSet indexSet];
        [marks setObject:indexes forKey:color];
    }
    [indexes addIndexes:lines];
    [self setNeedsDisplay];
    tapMarkRecognizer.enabled = YES;
}

- (void)removeAllMarks
{
    [marks removeAllObjects];
    tapMarkRecognizer.enabled = NO;
    [self setNeedsDisplay];
}

- (void)removaAllMarksWithColor:(UIColor *)color
{
    [marks removeObjectForKey:color];
    if ([marks count] == 0)
        tapMarkRecognizer.enabled = NO;
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Private methods

- (void)markTapped:(UITapGestureRecognizer *)recognizer
{
//    if (lineCount > 0 && [self.delegate respondsToSelector:@selector(lineMarksView:selectedMarkWithColor:atLine:)])
//    {
//        CGPoint point = [recognizer locationInView:self];
//        CGRect bounds = self.bounds;
//        CGFloat lineStep = (bounds.size.height - markInsets.top - markInsets.bottom ) / lineCount;
//        CGPoint markPoint = CGPointMake(bounds.origin.x + bounds.size.width - markSize.width - markInsets.right, markInsets.top);
//        CGSize tapSize = markSize;
//        tapSize.width += markInsets.left + markInsets.right;
//        tapSize.height = MAX(tapSize.height, lineStep);
//        [marks enumerateKeysAndObjectsUsingBlock:^(id color, id lines, BOOL *stop) {
//            [(NSMutableIndexSet *)lines enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *istop) {
//                if (idx < lineCount)
//                {
//                    CGRect markRect = (CGRect){ {markPoint.x, markPoint.y + lineStep * idx}, tapSize };
//                    if (CGRectContainsPoint(markRect, point))
//                    {
//                        [self.delegate lineMarksView:self selectedMarkWithColor:(UIColor *)color atLine:idx];
//                        *stop = YES;
//                    }
//                }
//            }];
//        }];
//    }
}

@end
