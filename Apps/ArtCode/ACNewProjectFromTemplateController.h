//
//  ACPopoverNewProjectFromTemplateController.h
//  ArtCode
//
//  Created by Uri Baghin on 9/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACNewProjectFromTemplateController : UITableViewController

@property (nonatomic, strong) void (^newProjectFromTemplate)(NSString *templateName);

@end
