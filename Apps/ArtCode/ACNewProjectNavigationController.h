//
//  ACNewProjectNavigationController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACProjectTableController.h"

@interface ACNewProjectNavigationController : UINavigationController

@property (nonatomic, strong) NSURL *projectsDirectory;
@property (nonatomic, weak) UIPopoverController *popoverController;
@property (nonatomic, weak) ACProjectTableController *parentController;

@end
