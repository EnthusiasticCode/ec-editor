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

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView willDisplayItem:(ECRelationalTableViewItem *)item forRowAtIndexPath:(NSIndexPath *)indexPath;

// Variable height support

- (CGFloat)relationalTableView:(ECRelationalTableView *)relationalTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)relationalTableView:(ECRelationalTableView *)relationalTableView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)relationalTableView:(ECRelationalTableView *)relationalTableView heightForFooterInSection:(NSInteger)section;

// Section header & footer information. Views are preferred over title should you decide to provide both

- (UIView *)relationalTableView:(ECRelationalTableView *)relationalTableView viewForHeaderInSection:(NSInteger)section;   // custom view for header. will be adjusted to default or specified header height
- (UIView *)relationalTableView:(ECRelationalTableView *)relationalTableView viewForFooterInSection:(NSInteger)section;   // custom view for footer. will be adjusted to default or specified footer height

// Selection

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath;
// Called after the user changes the selection.
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

// Editing

// Allows customization of the editingStyle for a particular item located at 'indexPath'. If not implemented, all editable items will have ECRelationalTableViewItemEditingStyleDelete set for them when the table has editing property set to YES.
- (ECRelationalTableViewItemEditingStyle)relationalTableView:(ECRelationalTableView *)relationalTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;

// Controls whether the background is indented while editing.  If not implemented, the default is YES.  This is unrelated to the indentation level below.  This method only applies to grouped style table views.
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath;

// The willBegin/didEnd methods are called whenever the 'editing' property is automatically changed by the table (allowing insert/delete/move). This is done by a swipe activating a single row
- (void)relationalTableView:(ECRelationalTableView*)relationalTableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)relationalTableView:(ECRelationalTableView*)relationalTableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows customization of the target row for a particular row as it is being moved/reordered
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;               

// Indentation

- (NSInteger)relationalTableView:(ECRelationalTableView *)relationalTableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath; // return 'depth' of row for hierarchies

@end
