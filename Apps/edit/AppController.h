//
//  AppController.h
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RootController;
@class ProjectController;
@class FileController;

@interface AppController : UINavigationController <UIApplicationDelegate>
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet RootController *rootController;
@property (nonatomic, strong) IBOutlet ProjectController *projectController;
@property (nonatomic, strong) IBOutlet FileController *fileController;
- (NSString *)applicationDocumentsDirectory;
@end
