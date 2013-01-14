//
//  RCIOItemCell.h
//  ArtCode
//
//  Created by Uri Baghin on 10/21/12.
//
//

#import "HighlightTableViewCell.h"

@class RCIOItem;

@interface RCIOItemCell : HighlightTableViewCell

@property (nonatomic, strong) RCIOItem *item;

@end
