//
//  ACFileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACToolFiltersView, ACGroup, ACTab;


@interface ACFileTableController : UITableViewController

@property (nonatomic, strong) NSURL *directory;

@property (nonatomic, strong) ACTab *tab;

@end
