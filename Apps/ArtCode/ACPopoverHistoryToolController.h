//
//  ACNavigationHistoryController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACPopoverHistoryToolController : UITableViewController

/// Sets the urls to be displayed by the table and the current history point.
- (void)setHistoryURLs:(NSArray *)urls hisoryPointIndex:(NSUInteger)index;

@end
