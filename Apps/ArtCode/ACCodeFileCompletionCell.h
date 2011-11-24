//
//  ACCodeFileCompletionCell.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACCodeFileCompletionCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *kindImageView;
@property (strong, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) IBOutlet UILabel *definitionLabel;

/// Set the size to give to the type label. If 0 the type label will be removed.
@property (nonatomic) CGFloat typeLabelSize;

@end
