//
//  ECHierarchicalTableView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECHierarchicalTableView.h"
#import "ECHierarchicalTableItemView.h"

@interface ECHierarchicalTableView ()
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *rootView;
@end

@implementation ECHierarchicalTableView

@synthesize scrollView = scrollView_;
@synthesize rootView = rootView_;
@synthesize delegate = delegate_;
@synthesize dataSource = dataSource_;
@synthesize inset = inset_;
@synthesize spacing = spacing_;
@synthesize indent = indent_;

- (void)dealloc
{
    self.scrollView = nil;
    self.rootView = nil;
    [super dealloc];
}

static id init(ECHierarchicalTableView *self)
{
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    [self addSubview:self.scrollView];
    self.rootView = [[[UIView alloc] init] autorelease];
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

- (void)layoutSubviews
{
    [super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
