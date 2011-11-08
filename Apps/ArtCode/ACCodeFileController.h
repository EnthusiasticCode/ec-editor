//
//  ACCodeFileController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECCodeView.h>
#import "ACCodeFileMinimapView.h"

@class ACTab;

@interface ACCodeFileController : UIViewController <ACCodeFileMinimapViewDelegate, ECCodeViewDelegate, UIActionSheetDelegate>

#pragma mark - Controller's location

/// The file URL that the controller is displaying
@property (nonatomic, strong) NSURL *fileURL;

/// The tab in which the controller is displayed.
@property (nonatomic, strong) ACTab *tab;

#pragma mark - Code viewing and editing

/// The code view used to display code.
@property (nonatomic, strong, readonly) ECCodeView *codeView;

/// The code minimap view.
@property (nonatomic, strong, readonly) ACCodeFileMinimapView *minimapView;

/// Indicates if the minimap is visible.
@property (nonatomic, getter = isMinimapVisible) BOOL minimapVisible;
- (void)setMinimapVisible:(BOOL)minimapVisible animated:(BOOL)animated;

/// Indicates the width of the minimap.
@property (nonatomic) CGFloat minimapWidth;

@end
