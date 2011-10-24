//
//  ACBottomTabBarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTab;

@interface ACSingleProjectBrowsersController : UITabBarController

@property (nonatomic, strong) ACTab *tab;

- (void)openFileBrowserWithURL:(NSURL *)url;
- (void)openRecentBrowserWithURL:(NSURL *)url;
- (void)openSymbolBrowserWithURL:(NSURL *)url;
- (void)openBookmarkBrowserWithURL:(NSURL *)url;

@end
