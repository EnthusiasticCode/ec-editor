//
//  ECRelationalTableView.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECRelationalTableViewDelegate.h"
#import "ECRelationalTableViewDataSource.h"

@interface ECRelationalTableView : UIView
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDataSource> dataSource;
@property (nonatomic) CGFloat inset;
@property (nonatomic) CGFloat spacing;
@property (nonatomic) CGFloat indent;
@end
