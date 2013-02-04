//
//  CodeFileController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CodeView.h"
#import "CodeFileMinimapView.h"
#import "TMKeyboardAction.h"

@class ArtCodeTab, TMTheme, TMUnit, RCIOFile;

@interface CodeFileController : UIViewController <CodeFileMinimapViewDelegate, CodeViewDelegate, UIActionSheetDelegate, UIWebViewDelegate, TMKeyboardActionTarget>

#pragma mark - Displayable Content

+ (BOOL)canDisplayFileInCodeView:(NSURL *)fileURL;

+ (BOOL)canDisplayFileInWebView:(NSURL *)fileURL;

#pragma mark - Code viewing and editing

// The code view used to display code.
@property (nonatomic, weak, readonly) CodeView *codeView;

@property (nonatomic, strong) RCIOFile *textFile;

@property (nonatomic, strong) TMUnit *codeUnit;

// The web view used for preview webpages.
@property (nonatomic, weak, readonly) UIWebView *webView;

// The code minimap view.
@property (nonatomic, weak, readonly) CodeFileMinimapView *minimapView;

// Indicates if the minimap is visible.
@property (nonatomic, getter = isMinimapVisible) BOOL minimapVisible;
- (void)setMinimapVisible:(BOOL)minimapVisible animated:(BOOL)animated;

// Indicates the width of the minimap.
@property (nonatomic) CGFloat minimapWidth;

@end
