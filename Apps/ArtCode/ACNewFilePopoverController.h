//
//  ACNewFilePopoverController.h
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACGroup;

@interface ACNewFilePopoverController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) ACGroup *group;

@property (nonatomic, strong) IBOutlet UIButton *folderButton;
@property (nonatomic, strong) IBOutlet UIButton *groupButton;
@property (nonatomic, strong) IBOutlet UIButton *fileButton;

@property (nonatomic, strong) IBOutlet UITableView *fileImportTableView;

@end
