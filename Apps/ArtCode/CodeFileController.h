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

@class ArtCodeTab, TMTheme, TMUnit, TextFile;

@interface CodeFileController : UIViewController <CodeFileMinimapViewDelegate, CodeViewDelegate, UIActionSheetDelegate, UIWebViewDelegate, TMKeyboardActionTarget>

#pragma mark - Displayable Content

+ (BOOL)canDisplayFileInCodeView:(NSURL *)fileURL;

+ (BOOL)canDisplayFileInWebView:(NSURL *)fileURL;

#pragma mark - Code viewing and editing

/// The code view used to display code.
@property (nonatomic, strong, readonly) CodeView *codeView;

@property (nonatomic, strong) TextFile *textFile;

@property (nonatomic, strong) TMUnit *codeUnit;

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
//- (void)showCompletionPopoverForCurrentSelectionAtKeyboardAccessoryItemIndex:(NSUInteger)accessoryItemIndex;

@end
