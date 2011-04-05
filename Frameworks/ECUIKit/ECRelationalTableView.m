//
//  ECRelationalTableView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRelationalTableView.h"
#import "ECRelationalTableViewItem.h"
#import "ECRelationalTableViewItem(Private).h"

@interface ECRelationalTableView ()
{
    @private
    struct {
        unsigned int dataSourceNumberOfItemsInSection:1;
        unsigned int dataSourceItemForIndexPath:1;
        unsigned int dataSourceNumberOfSectionsInTableView:1;
        unsigned int dataSourceTitleForHeaderInSection:1;
        unsigned int dataSourceTitleForFooterInSection:1;
        unsigned int dataSourceCommitEditingStyle:1;
        unsigned int dataSourceCanEditItem:1;
        unsigned int dataSourceCanMoveItem:1;
        unsigned int dataSourceMoveItem:1;
//		  unsigned int dataSourceCanUpdateItem:1;
//        unsigned int dataSourceCanPerformAction:1;
//        unsigned int dataSourcePerformAction:1;
        unsigned int delegateEditingStyleForItem:1;
        unsigned int delegateTitleForDeleteConfirmationButtonForItem:1;
        unsigned int delegateWillDisplayItem:1;
        unsigned int delegateHeightForSectionHeader:1;
        unsigned int delegateHeightForSectionFooter:1;
        unsigned int delegateViewForHeaderInSection:1;
        unsigned int delegateViewForFooterInSection:1;
//        unsigned int delegateAccessoryTypeForItem:1;
//        unsigned int delegateAccessoryButtonTappedForItem:1;
        unsigned int delegateWillSelectItem:1;
        unsigned int delegateWillDeselectItem:1;
        unsigned int delegateDidSelectItem:1;
        unsigned int delegateDidDeselectItem:1;
        unsigned int delegateWillBeginEditing:1;
        unsigned int delegateDidEndEditing:1;
        unsigned int delegateWillMoveToItem:1;
        unsigned int delegateIndentationLevelForItem:1;
        unsigned int delegateHeaderTitleAlignment:1;
        unsigned int delegateFooterTitleAlignment:1;
//        unsigned int delegateDidFinishReload:1;
        unsigned int delegateHeightForHeader:1;
        unsigned int delegateHeightForFooter:1;
        unsigned int delegateViewForHeader:1;
        unsigned int delegateViewForFooter:1;
        unsigned int wasEditing:1;
        unsigned int isEditing:1;
        unsigned int scrollsToSelection:1;
        unsigned int updating:1;
        unsigned int needsReload:1;
        unsigned int ignoreDragSwipe:1;        
        unsigned int ignoreTouchSelect:1;
        unsigned int allowsSelection:1;
        unsigned int allowsSelectionDuringEditing:1;
        unsigned int showsSelectionImmediatelyOnTouchBegin:1;
        unsigned int defaultShowsHorizontalScrollIndicator:1;
        unsigned int defaultShowsVerticalScrollIndicator:1;
        unsigned int hideScrollIndicators:1;
        unsigned int keepFirstResponderWhenInteractionDisabled:1;
        unsigned int keepFirstResponderVisibleOnBoundsChange:1;
        unsigned int growthDirection:2;
        unsigned int indentDirection:2;
        unsigned int wrapping:2;
    } flags_;
}
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *rootView;
@property (nonatomic, retain) NSMutableArray *sectionHeaders;
@property (nonatomic, retain) NSMutableArray *sectionFooters;
@property (nonatomic, retain) NSMutableArray *sectionItems;
@end

@implementation ECRelationalTableView

@synthesize scrollView = scrollView_;
@synthesize rootView = rootView_;
@synthesize sectionHeaders = sectionHeaders_;
@synthesize sectionFooters = sectionFooters_;
@synthesize sectionItems = sectionItems_;
@synthesize delegate = delegate_;
@synthesize dataSource = dataSource_;
@synthesize tableInsets = tableInsets_;
@synthesize itemInsets = itemInsets_;
@synthesize indentInsets = indentInsets_;
@synthesize sectionHeaderInsets = sectionHeaderInsets_;
@synthesize sectionFooterInsets = sectionFooterInsets_;
@synthesize sectionHeaderHeight = sectionHeaderHeight_;
@synthesize sectionFooterHeight = sectionFooterHeight_;
@synthesize backgroundView = backgroundView_;
@synthesize tableHeaderView = tableHeaderView_;
@synthesize tableFooterView = tableFooterView_;

- (BOOL)isEditing
{
    return flags_.isEditing;
}

- (void)setEditing:(BOOL)editing
{
    flags_.isEditing = editing;
}

- (BOOL)allowsSelection
{
    return flags_.allowsSelection;
}

- (void)setAllowsSelection:(BOOL)allowsSelection
{
    flags_.allowsSelection = allowsSelection;
}

- (BOOL)allowsSelectionDuringEditing
{
    return flags_.allowsSelectionDuringEditing;
}

- (void)setAllowsSelectionDuringEditing:(BOOL)allowsSelectionDuringEditing
{
    flags_.allowsSelectionDuringEditing = allowsSelectionDuringEditing;
}

- (ECRelationalTableViewGrowthDirection)growthDirection
{
    return flags_.growthDirection;
}

- (void)setGrowthDirection:(ECRelationalTableViewGrowthDirection)growthDirection
{
    flags_.growthDirection = growthDirection;
}

- (ECRelationalTableViewIndentDirection)indentDirection
{
    return flags_.indentDirection;
}

- (void)setIndentDirection:(ECRelationalTableViewIndentDirection)indentDirection
{
    flags_.indentDirection = indentDirection;
}

- (ECRelationalTableViewWrapping)wrapping
{
    return flags_.wrapping;
}

- (void)setWrapping:(ECRelationalTableViewWrapping)wrapping
{
    flags_.wrapping = wrapping;
}

- (void)setDelegate:(id<ECRelationalTableViewDelegate>)delegate
{
    if (delegate == delegate_)
        return;
    delegate_ = delegate;
    flags_.delegateWillDisplayItem = [delegate respondsToSelector:@selector(relationalTableView:willDisplayItem:forIndexPath:)];
    flags_.delegateHeaderTitleAlignment = [delegate respondsToSelector:@selector(relationalTableView:alignmentForHeaderTitleInSection:)];
    flags_.delegateFooterTitleAlignment = [delegate respondsToSelector:@selector(relationalTableView:alignmentForFooterTitleInSection:)];
    flags_.delegateHeightForHeader = [delegate respondsToSelector:@selector(heightForHeaderInTableView:)];
    flags_.delegateHeightForFooter = [delegate respondsToSelector:@selector(heightForFooterInTableView:)];
    flags_.delegateViewForHeader = [delegate respondsToSelector:@selector(headerForTableView:)];
    flags_.delegateViewForFooter = [delegate respondsToSelector:@selector(footerForTableView:)];
    flags_.delegateHeightForHeader = [delegate respondsToSelector:@selector(relationalTableView:heightForHeaderInSection:)];
    flags_.delegateHeightForFooter = [delegate respondsToSelector:@selector(relationalTableView:heightForFooterInSection:)];
    flags_.delegateViewForHeaderInSection = [delegate respondsToSelector:@selector(relationalTableView:viewForHeaderInSection:)];
    flags_.delegateViewForFooterInSection = [delegate respondsToSelector:@selector(relationalTableView:viewForFooterInSection:)];
    flags_.delegateWillSelectItem = [delegate respondsToSelector:@selector(relationalTableView:willSelectItemAtIndexPath:)];
    flags_.delegateWillDeselectItem = [delegate respondsToSelector:@selector(relationalTableView:willDeselectItemAtIndexPath:)];
    flags_.delegateDidSelectItem = [delegate respondsToSelector:@selector(relationalTableView:didSelectItemAtIndexPath:)];
    flags_.delegateDidDeselectItem = [delegate respondsToSelector:@selector(relationalTableView:didDeselectItemAtIndexPath:)];
    flags_.delegateEditingStyleForItem = [delegate respondsToSelector:@selector(relationalTableView:editingStyleForItemAtIndexPath:)];
    flags_.delegateTitleForDeleteConfirmationButtonForItem = [delegate respondsToSelector:@selector(relationalTableView:titleForDeleteConfirmationButtonForItemAtIndexPath:)];
    flags_.delegateWillBeginEditing = [delegate respondsToSelector:@selector(relationalTableView:willBeginEditingItemAtIndexPath:)];
    flags_.delegateDidEndEditing = [delegate respondsToSelector:@selector(relationalTableView:didEndEditingItemAtIndexPath:)];
    flags_.delegateWillMoveToItem = [delegate respondsToSelector:@selector(relationalTableView:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:)];
}

- (void)setDataSource:(id<ECRelationalTableViewDataSource>)dataSource
{
    if (dataSource == dataSource_)
        return;
    dataSource_ = dataSource;
    flags_.dataSourceNumberOfItemsInSection = [dataSource respondsToSelector:@selector(relationalTableView:numberOfItemsInSection:)];
    flags_.dataSourceItemForIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:itemForIndexPath:)];
    flags_.dataSourceNumberOfSectionsInTableView = [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)];
    flags_.dataSourceTitleForHeaderInSection = [dataSource respondsToSelector:@selector(relationalTableView:titleForHeaderInSection:)];
    flags_.dataSourceTitleForFooterInSection = [dataSource respondsToSelector:@selector(relationalTableView:titleForFooterInSection:)];
    flags_.dataSourceCanEditItem = [dataSource respondsToSelector:@selector(relationalTableView:canEditItemAtIndexPath:)];
    flags_.dataSourceCanMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:canMoveItemAtIndexPath:)];
    flags_.dataSourceCommitEditingStyle = [dataSource respondsToSelector:@selector(relationalTableView:commitEditingStyle:forItemAtIndexPath:)];
    flags_.dataSourceMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:moveItemAtIndexPath:toIndexPath:)];
}

- (void)dealloc
{
    self.scrollView = nil;
    self.rootView = nil;
    [super dealloc];
}

static id init(ECRelationalTableView *self)
{
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    [self addSubview:self.scrollView];
    self.rootView = [[[UIView alloc] init] autorelease];
    [self.scrollView addSubview:self.rootView];
    self.sectionHeaders = [NSMutableArray array];
    self.sectionFooters = [NSMutableArray array];
    self.sectionItems = [NSMutableArray array];
    self->flags_.needsReload = YES;
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
    if (flags_.needsReload)
        [self reloadData];
    [super layoutSubviews];
    CGFloat currentX;
    CGFloat maxX;
    CGFloat currentY = self.tableInsets.top;
    NSUInteger numSections = [self.sectionHeaders count];
    for (NSUInteger i = 0; i < numSections; i++)
    {
        currentX = self.tableInsets.left;
        UIView *header = [self.sectionHeaders objectAtIndex:i];
        if (![header superview])
            [self.rootView addSubview:header];
        header.backgroundColor = [UIColor blueColor];
        header.frame = CGRectMake(currentX + self.sectionHeaderInsets.left, currentY + self.sectionHeaderInsets.top, 0.0, 0.0);
        [header sizeToFit];
        NSArray *itemsInSection = [self.sectionItems objectAtIndex:i];
        currentY += header.frame.size.height + self.sectionHeaderInsets.top + self.sectionHeaderInsets.bottom;
        for (NSUInteger j = 0; j < [itemsInSection count]; j++)
        {
            NSUInteger itemDepth = 0;
            if (flags_.delegateIndentationLevelForItem)
                itemDepth = [self.delegate relationalTableView:self indentationLevelForItemAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
            ECRelationalTableViewItem *item = [itemsInSection objectAtIndex:j];
            UIView *itemView = item.contentView;
            if (![itemView superview])
                [self.rootView addSubview:itemView];
            itemView.frame = CGRectMake(currentX + self.itemInsets.left, currentY + self.itemInsets.top, 100.0, 100.0);
            currentX += itemView.frame.size.width + self.itemInsets.left + self.itemInsets.right;
            if (currentX > maxX)
                maxX = currentX;
        }
        currentY += 100.0 + self.itemInsets.top + self.itemInsets.bottom;
    }
    for (UIView *header in self.sectionHeaders)
    {
        CGRect newFrame = header.frame;
        newFrame.size.width = maxX - self.tableInsets.left - self.sectionHeaderInsets.left - self.sectionHeaderInsets.right;
        header.frame = newFrame;
    }
    self.rootView.frame = CGRectMake(0.0, 0.0, maxX + self.tableInsets.right, currentY + self.tableInsets.bottom);
    self.scrollView.contentSize = self.rootView.frame.size;
}

- (void)reloadData
{
    // clear all data
    [self.sectionHeaders removeAllObjects];
    [self.sectionFooters removeAllObjects];
    [self.sectionItems removeAllObjects];
    
    // count number of sections
    NSUInteger sections = 1;
    if (flags_.dataSourceNumberOfSectionsInTableView)
        sections = [self.dataSource numberOfSectionsInTableView:self];
    if (!sections)
        return;
    
    // get or create view for headers
    if (flags_.delegateViewForHeaderInSection)
        for (NSUInteger i = 0; i < sections; i++)
            [self.sectionHeaders addObject:[self.delegate relationalTableView:self viewForHeaderInSection:i]];
    else if (flags_.dataSourceTitleForHeaderInSection)
        for (NSUInteger i = 0; i < sections; i++)
        {
            NSString *sectionTitle = [self.dataSource relationalTableView:self titleForHeaderInSection:i];
            UILabel *sectionHeaderLabel = [[[UILabel alloc] init] autorelease];
            sectionHeaderLabel.text = sectionTitle;
            [self.sectionHeaders addObject:sectionHeaderLabel];
        }
    
    // get items
    if (flags_.dataSourceItemForIndexPath)
    {
        for (NSUInteger i = 0; i < sections; i++)
        {
            NSMutableArray *currentSection = [NSMutableArray array];
            [self.sectionItems addObject:currentSection];
            NSUInteger numItems = 0;
            if (flags_.dataSourceNumberOfItemsInSection)
                numItems = [self.dataSource relationalTableView:self numberOfItemsInSection:i];
            if (!numItems)
                continue;
            for (NSUInteger j = 0; j < numItems; j++)
            {
                NSUInteger itemDepth = 0;
                NSIndexPath *itemIndexPath = [NSIndexPath indexPathForRow:j inSection:i];
                ECRelationalTableViewItem *item = [self.dataSource relationalTableView:self itemForIndexPath:itemIndexPath];
                if (flags_.delegateIndentationLevelForItem)
                    itemDepth = [self.delegate relationalTableView:self indentationLevelForItemAtIndexPath:itemIndexPath];
                [currentSection addObject:item];
            }
        }
    }
    flags_.needsReload = NO;
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
