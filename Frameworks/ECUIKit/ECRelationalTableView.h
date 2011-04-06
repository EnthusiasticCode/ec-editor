//
//  ECRelationalTableView.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECRelationalTableView : UITableView
@property (nonatomic) UIEdgeInsets tableInsets;
@property (nonatomic) UIEdgeInsets cellInsets;
@property (nonatomic) UIEdgeInsets indentInsets;
@property (nonatomic) UIEdgeInsets sectionHeaderInsets;
@property (nonatomic) UIEdgeInsets sectionFooterInsets;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, readonly) CGSize paddedCellSize;
@property (nonatomic, readonly) CGSize paddedSectionHeaderSize;
@property (nonatomic, readonly) NSInteger widthInCells;
- (NSInteger)heightInCellsForContentInSection:(NSInteger)section;
@end
