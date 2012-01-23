//
//  ACBookmarkTableController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTab;


@interface ACBookmarkTableController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, strong) ACTab *tab;

@end
