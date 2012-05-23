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
#import "ACProjectFile.h"
#import "TMKeyboardAction.h"

@class ArtCodeTab, TMTheme, TMUnit;

@interface CodeFileController : UIViewController <CodeFileMinimapViewDelegate, CodeViewDataSource, CodeViewDelegate, UIActionSheetDelegate, UIWebViewDelegate, TMKeyboardActionTarget>

#pragma mark - Controller's location

@property (nonatomic, strong, readonly) ACProjectFile *projectFile;

#pragma mark - Code viewing and editing

/// The code view used to display code.
@property (nonatomic, strong, readonly) CodeView *codeView;

@property (nonatomic, strong, readonly) TMUnit *codeUnit;

/// The web view used for preview webpages.
@property (nonatomic, strong, readonly) UIWebView *webView;

/// The code minimap view.
@property (nonatomic, strong, readonly) CodeFileMinimapView *minimapView;

/// Indicates if the minimap is visible.
@property (nonatomic, getter = isMinimapVisible) BOOL minimapVisible;
- (void)setMinimapVisible:(BOOL)minimapVisible animated:(BOOL)animated;

/// Indicates the width of the minimap.
@property (nonatomic) CGFloat minimapWidth;

#pragma mark - Code completion

/// Generate and shows a keyboard accessory popover at the specified item index 
/// containing the completions for the cursor. If no completions are available
/// a bezel alert will be shown instead.
- (void)showCompletionPopoverForCurrentSelectionAtKeyboardAccessoryItemIndex:(NSUInteger)accessoryItemIndex;

@end
