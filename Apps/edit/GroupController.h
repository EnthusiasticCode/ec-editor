//
//  GroupController.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class Node;

@interface GroupController : UITableViewController
@property (nonatomic, strong) Node *group;
- (void)loadNode:(Node *)node;
@end
