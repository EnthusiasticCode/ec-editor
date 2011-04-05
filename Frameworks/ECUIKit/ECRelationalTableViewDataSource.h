//
//  ECRelationalTableViewDataSource.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECRelationalTableViewItem.h"
@class ECRelationalTableView;
@class ECRelationalTableViewItem;

@protocol ECRelationalTableViewDataSource <NSObject>
@required

- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfItemsInSection:(NSUInteger)section;

// Item gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (ECRelationalTableViewItem *)relationalTableView:(ECRelationalTableView *)relationalTableView itemForIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfSectionsInTableView:(ECRelationalTableView *)relationalTableView;              // Default is 1 if not implemented

- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForHeaderInSection:(NSUInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForFooterInSection:(NSUInteger)section;

// Editing

// Individual items can opt out of having the -editing property set for them. If not implemented, all items are assumed to be editable.
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canEditItemAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular item. By default, the reorder control will be shown only if the datasource implements -relationalTableView:moveItemAtIndexPath:toIndexPath:
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

// Data manipulation - insert and delete support

// After a item has the minus or plus button invoked (based on the ECRelationalTableViewItemEditingStyle for the item), the dataSource must commit the change
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView commitEditingStyle:(ECRelationalTableViewItemEditingStyle)editingStyle forItemAtIndexPath:(NSIndexPath *)indexPath;

// Data manipulation - reorder / moving support

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end
