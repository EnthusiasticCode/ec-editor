//
//  ECHierarchicalTableView.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECHierarchicalTableViewDelegate.h"
#import "ECHierarchicalTableViewDataSource.h"

@interface ECHierarchicalTableView : UIView
@property (nonatomic, assign) IBOutlet id<ECHierarchicalTableViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<ECHierarchicalTableViewDataSource> dataSource;
@property (nonatomic) CGFloat inset;
@property (nonatomic) CGFloat spacing;
@property (nonatomic) CGFloat indent;
@end
