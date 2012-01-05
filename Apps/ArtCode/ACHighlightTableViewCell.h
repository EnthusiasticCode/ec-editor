//
//  ACHighlightTableViewCell.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACHighlightLabel.h"

@interface ACHighlightTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) ACHighlightLabel *highlightLabel;

@end
