//
//  PopoverTableController.h
//  edit
//
//  Created by Uri Baghin on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UITableViewController.h>
#import "PopoverTableControllerDelegate.h"

@interface PopoverTableController : UITableViewController{
    NSArray *_resultsList;
}
@property (nonatomic,retain) NSArray *resultsList;
@property (nonatomic,assign) id <PopoverTableControllerDelegate> delegate;

@end
