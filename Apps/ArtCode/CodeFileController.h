//
//  CodeFileController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CodeView.h"
#import "FileBuffer.h"
#import "CodeFileMinimapView.h"

@class ArtCodeTab, CodeFile;

@interface CodeFileController : UIViewController <CodeFileMinimapViewDelegate, CodeViewDelegate, UIActionSheetDelegate, FileBufferConsumer, UIWebViewDelegate>

#pragma mark - Controller's location

/// The file URL that the controller is displaying
@property (nonatomic, strong) NSURL *fileURL;

@property (nonatomic, strong, readonly) CodeFile *codeFile;

#pragma mark - Code viewing and editing

/// The code view used to display code.
@property (nonatomic, strong, readonly) CodeView *codeView;

/// The web view used for preview webpages.
@property (nonatomic, strong, readonly) UIWebView *webView;

/// The code minimap view.
@property (nonatomic, strong, readonly) CodeFileMinimapView *minimapView;

/// Indicates if the minimap is visible.
@property (nonatomic, getter = isMinimapVisible) BOOL minimapVisible;
- (void)setMinimapVisible:(BOOL)minimapVisible animated:(BOOL)animated;

/// Indicates the width of the minimap.
@property (nonatomic) CGFloat minimapWidth;

@end
