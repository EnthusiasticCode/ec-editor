//
//  HighlightTableViewCell.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HighlightTableViewCell : UITableViewCell

/// Index in the label text characters to which highlight the background.
@property (nonatomic, strong) NSIndexSet *textLabelHighlightedCharacters;

/// Indicate the color to be used for background highlighting.
@property (nonatomic, strong) UIColor *textLabelHighlightedCharactersBackgroundColor UI_APPEARANCE_SELECTOR;

@end
