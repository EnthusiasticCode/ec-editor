//
//  NewProjectNavigationController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectBrowserController.h"
#import "UIViewController+PresentingPopoverController.h"

@interface NewProjectNavigationController : UINavigationController

@property (nonatomic, strong) NSURL *projectsDirectory;

@end
