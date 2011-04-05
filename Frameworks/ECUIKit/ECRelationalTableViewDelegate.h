//
//  ECRelationalTableViewDelegate.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECRelationalTableViewItem.h"
@class ECRelationalTableView;
@class ECRelationalTableViewItem;

@protocol ECRelationalTableViewDelegate <NSObject, UIScrollViewDelegate>

@optional

// Display customization

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView willDisplayItem:(ECRelationalTableViewItem *)item forIndexPath:(NSIndexPath *)indexPath;

- (UIControlContentHorizontalAlignment)relationalTableView:(ECRelationalTableView *)relationalTableView alignmentForHeaderTitleInSection:(NSUInteger)section;

- (UIControlContentHorizontalAlignment)relationalTableView:(ECRelationalTableView *)relationalTableView alignmentForFooterTitleInSection:(NSUInteger)section;

// Variable height support

- (CGFloat)heightForHeaderInTableView:(ECRelationalTableView *)relationalTableView;
- (CGFloat)heightForFooterInTableView:(ECRelationalTableView *)relationalTableView;

// Section header & footer information. Views are preferred over title should you decide to provide both

- (UIView *)headerForTableView:(ECRelationalTableView *)relationalTableView;   // custom view for header. will be adjusted to default or specified header height
- (UIView *)footerForTableView:(ECRelationalTableView *)relationalTableView;   // custom view for footer. will be adjusted to default or specified footer height


// Variable height support

- (CGFloat)relationalTableView:(ECRelationalTableView *)relationalTableView heightForHeaderInSection:(NSUInteger)section;
- (CGFloat)relationalTableView:(ECRelationalTableView *)relationalTableView heightForFooterInSection:(NSUInteger)section;

// Section header & footer information. Views are preferred over title should you decide to provide both

- (UIView *)relationalTableView:(ECRelationalTableView *)relationalTableView viewForHeaderInSection:(NSUInteger)section;   // custom view for header. will be adjusted to default or specified header height
- (UIView *)relationalTableView:(ECRelationalTableView *)relationalTableView viewForFooterInSection:(NSUInteger)section;   // custom view for footer. will be adjusted to default or specified footer height

// Selection

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
// Called after the user changes the selection.
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

// Editing

// Allows customization of the editingStyle for a particular item located at 'indexPath'. If not implemented, all editable items will have ECRelationalTableViewItemEditingStyleDelete set for them when the table has editing property set to YES.
- (ECRelationalTableViewItemEditingStyle)relationalTableView:(ECRelationalTableView *)relationalTableView editingStyleForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForDeleteConfirmationButtonForItemAtIndexPath:(NSIndexPath *)indexPath;

// The willBegin/didEnd methods are called whenever the 'editing' property is automatically changed by the table (allowing insert/delete/move). This is done by a swipe activating a single item
- (void)relationalTableView:(ECRelationalTableView*)relationalTableView willBeginEditingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)relationalTableView:(ECRelationalTableView*)relationalTableView didEndEditingItemAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows customization of the target item for a particular item as it is being moved/reordered
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;               

// Indentation

- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView indentationLevelForItemAtIndexPath:(NSIndexPath *)indexPath; // return 'depth' of item for hierarchies

@end
