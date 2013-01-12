//
//  FileSystemItemCell.h
//  ArtCode
//
//  Created by Uri Baghin on 10/21/12.
//
//

#import "HighlightTableViewCell.h"

@class FileSystemItem;

@interface FileSystemItemCell : HighlightTableViewCell

@property (nonatomic, strong) FileSystemItem *item;

@end
