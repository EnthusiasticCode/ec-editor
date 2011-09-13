//
//  ACNewProjectPopoverController.h
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACNewProjectPopoverController : UINavigationController

@property (nonatomic, strong) void (^newProjectFromTemplate)(NSString *templateName);

@property (nonatomic, strong) void (^newProjectFromACZ)(NSURL *ACZFileURL);

@property (nonatomic, strong) void (^newProjectFromZIP)(NSURL *ZIPFileURL);

@end
