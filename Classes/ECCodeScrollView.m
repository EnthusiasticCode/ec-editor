//
//  ECCodeScrollView.m
//  edit
//
//  Created by Nicola Peduzzi on 01/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeScrollView.h"


@implementation ECCodeScrollView

@synthesize marks;

static inline id init(ECCodeScrollView *self)
{
    self->marks = [[ECLineMarksView alloc] initWithFrame:[self bounds]];
    [self addSubview:self->marks];
    return self;
}

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

- (void)dealloc {
    self.marks = nil;
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (marks)
    {
        CGRect bounds = self.bounds;
        CGSize markSize = [marks sizeThatFits:bounds.size];
        CGFloat offset = bounds.size.width - markSize.width;
        bounds.origin.x += offset;
        bounds.size.width -= offset;
        marks.frame = bounds;
        [self bringSubviewToFront:marks];
    }
}

@end
