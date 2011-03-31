//
//  ECDoubleOutlineView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDoubleOutlineView.h"

@interface ECDoubleOutlineView ()
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *rootView;
@end

@implementation ECDoubleOutlineView

@synthesize scrollView = scrollView_;
@synthesize rootView = rootView_;

static id init(ECDoubleOutlineView *self)
{
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    [self addSubview:self.scrollView];
    self.rootView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    [self.scrollView addSubview:self.rootView];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    self.userInteractionEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return init(self);
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
        return nil;
    return init(self);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    self.scrollView = nil;
    self.rootView = nil;
    [super dealloc];
}

@end
