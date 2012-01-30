//
//  NewProjectNavigationController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectTableController.h"

@interface NewProjectNavigationController : UINavigationController

@property (nonatomic, strong) NSURL *projectsDirectory;
@property (nonatomic, weak) UIPopoverController *popoverController;
@property (nonatomic, weak) ProjectTableController *parentController;

@end
