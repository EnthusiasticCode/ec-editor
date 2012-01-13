//
//  ACNewProjectNavigationController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACNewProjectNavigationController : UINavigationController

@property (nonatomic, strong) NSURL *projectsDirectory;
@property (nonatomic, weak) UIPopoverController *popoverController;

@end
