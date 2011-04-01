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

- (NSInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfRowsInSection:(NSInteger)section;

// Row display. Implementers should *always* try to reuse items by setting each item's reuseIdentifier and querying for available reusable items with dequeueReusableItemWithIdentifier:
// Item gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (ECRelationalTableViewItem *)relationalTableView:(ECRelationalTableView *)relationalTableView itemForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSInteger)numberOfSectionsInTableView:(ECRelationalTableView *)relationalTableView;              // Default is 1 if not implemented

- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForFooterInSection:(NSInteger)section;

// Editing

// Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -relationalTableView:moveRowAtIndexPath:toIndexPath:
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;

// Index
/*
- (NSArray *)sectionIndexTitlesForTableView:(ECRelationalTableView *)relationalTableView;                                                    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
- (NSInteger)relationalTableView:(ECRelationalTableView *)relationalTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;  // tell table which section corresponds to section title/index (e.g. "B",1))
*/
// Data manipulation - insert and delete support

// After a row has the minus or plus button invoked (based on the ECRelationalTableViewItemEditingStyle for the item), the dataSource must commit the change
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView commitEditingStyle:(ECRelationalTableViewItemEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;

// Data manipulation - reorder / moving support

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end
