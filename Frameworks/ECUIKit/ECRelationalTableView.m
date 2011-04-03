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
        unsigned int delegateEditingStyleForItemAtIndexPath:1;
        unsigned int delegateTitleForDeleteConfirmationButtonForItemAtIndexPath:1;
        unsigned int delegateShouldIndentWhileEditing:1;
        unsigned int delegateItemForItem:1;
        unsigned int delegateWillDisplayItem:1;
        unsigned int delegateHeightForItem:1;
        unsigned int delegateHeightForSectionHeader:1;
        unsigned int delegateTitleWidthForSectionHeader:1;
        unsigned int delegateHeightForSectionFooter:1;
        unsigned int delegateTitleWidthForSectionFooter:1;
        unsigned int delegateViewForHeaderInSection:1;
        unsigned int delegateViewForFooterInSection:1;
        unsigned int delegateDisplayedItemCountForItemCount:1;
        unsigned int delegateDisplayStringForItemCount:1;
        unsigned int delegateAccessoryTypeForItem:1;
        unsigned int delegateAccessoryButtonTappedForItem:1;
        unsigned int delegateWillSelectItem:1;
        unsigned int delegateWillDeselectItem:1;
        unsigned int delegateDidSelectItem:1;
        unsigned int delegateDidDeselectItem:1;
        unsigned int delegateWillBeginEditing:1;
        unsigned int delegateDidEndEditing:1;
        unsigned int delegateWillMoveToItem:1;
        unsigned int delegateIndentationLevelForItem:1;
        unsigned int delegateWantsHeaderForSection:1;
        unsigned int delegateHeightForItemsInSection:1;
        unsigned int delegateMargin:1;
        unsigned int delegateHeaderTitleAlignment:1;
        unsigned int delegateFooterTitleAlignment:1;
        unsigned int delegateFrameForSectionIndexGivenProposedFrame:1;
        unsigned int delegateDidFinishReload:1;
        unsigned int delegateHeightForHeader:1;
        unsigned int delegateHeightForFooter:1;
        unsigned int delegateViewForHeader:1;
        unsigned int delegateViewForFooter:1;
        unsigned int style:1;
        unsigned int separatorStyle:3;
        unsigned int wasEditing:1;
        unsigned int isEditing:1;
        unsigned int scrollsToSelection:1;
        unsigned int reloadSkippedDuringSuspension:1;
        unsigned int updating:1;
        unsigned int displaySkippedDuringSuspension:1;
        unsigned int needsReload:1;
        unsigned int updatingVisibleItemsManually:1;
        unsigned int scheduledUpdateVisibleItems:1;
        unsigned int scheduledUpdateVisibleItemsFrames:1;
        unsigned int warnForForcedItemUpdateDisabled:1;
        unsigned int displayTopSeparator:1;
        unsigned int countStringInsignificantItemCount:4;
        unsigned int needToAdjustExtraSeparators:1;
        unsigned int overlapsSectionHeaderViews:1;
        unsigned int ignoreDragSwipe:1;        
        unsigned int ignoreTouchSelect:1;
        unsigned int lastHighlightedItemActive:1;
        unsigned int reloading:1;
        unsigned int allowsSelection:1;
        unsigned int allowsSelectionDuringEditing:1;
        unsigned int showsSelectionImmediatelyOnTouchBegin:1;
        unsigned int indexHidden:1;
        unsigned int indexHiddenForSearch:1;
        unsigned int defaultShowsHorizontalScrollIndicator:1;
        unsigned int defaultShowsVerticalScrollIndicator:1;
        unsigned int sectionIndexTitlesLoaded:1;
        unsigned int tableHeaderViewShouldAutoHide:1;
        unsigned int tableHeaderViewIsHidden:1;
        unsigned int tableHeaderViewWasHidden:1;
        unsigned int hideScrollIndicators:1;
        unsigned int sendReloadFinished:1;
        unsigned int keepFirstResponderWhenInteractionDisabled:1;
        unsigned int keepFirstResponderVisibleOnBoundsChange:1;
        unsigned int dontDrawTopShadowInGroupedSections:1;
    } flags_;
}
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *rootView;
@end

@implementation ECRelationalTableView

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

static id init(ECRelationalTableView *self)
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
