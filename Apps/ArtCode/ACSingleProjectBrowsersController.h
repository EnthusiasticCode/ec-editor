//
//  ACBottomTabBarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACSingleTabController.h"
#import "ACProject.h"

@class ACTab;

@interface ACSingleProjectBrowsersController : UITabBarController <ACSingleTabContentController, UITextFieldDelegate>

@property (nonatomic, strong) ACTab *tab;
@property (nonatomic, strong, readonly) ACProject *project;

- (void)openFileBrowserWithURL:(NSURL *)url;
//- (void)openBookmarkBrowserWithURL:(NSURL *)url;
//- (void)openRemotesBrowserWithURL:(NSURL *)url;

@end


@interface UIViewController (ACSingleProjectBrowsersController)

- (ACSingleProjectBrowsersController *)singleProjectBrowsersController;

@end