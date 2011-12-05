//
//  ACProjectsTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GMGridView.h"
@class ACApplication, ACTab, ACProjectCell;

@interface ACProjectTableController : UIViewController <UITextFieldDelegate, GMGridViewDataSource>

@property (nonatomic, strong) NSURL *projectsDirectory;

@property (nonatomic, strong) ACTab *tab;

@end
