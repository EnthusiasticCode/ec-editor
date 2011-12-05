//
//  ACProjectCell.h
//  ArtCode
//
//  Created by Uri Baghin on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GMGridViewCell.h"
@class ACProjectCellNormalView, ACProjectCellEditingView;

@interface ACProjectCell : GMGridViewCell

@property (strong, nonatomic) IBOutlet ACProjectCellNormalView *normalView;
@property (strong, nonatomic) IBOutlet ACProjectCellEditingView *editingView;

@end
