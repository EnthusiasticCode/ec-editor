//
//  ECPopoverController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECPopoverView.h"


/// Replace the \c UIPopoverController with a popovercontroller that is customizable.
@interface ECPopoverController : NSObject

#pragma mark UIPopoverController Methods

- (id)initWithContentViewController:(UIViewController *)viewController;

@property (nonatomic, weak) id <UIPopoverControllerDelegate> delegate;

@property (nonatomic, strong) UIViewController *contentViewController;
- (void)setContentViewController:(UIViewController *)viewController animated:(BOOL)animated;

@property (nonatomic) CGSize popoverContentSize;
- (void)setPopoverContentSize:(CGSize)size animated:(BOOL)animated;

@property (nonatomic, readonly, getter=isPopoverVisible) BOOL popoverVisible;

@property (nonatomic, readonly) UIPopoverArrowDirection popoverArrowDirection;

@property (nonatomic, copy) NSArray *passthroughViews;

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)dismissPopoverAnimated:(BOOL)animated;

#pragma mark Customizable Popover

@property (nonatomic, readonly, strong) ECPopoverView *popoverView;

#pragma mark Advanced Behaviours

/// If YES (default), the user will be able to dismiss the popover by tapping anyehere outside it and passthroughViews views.
@property (nonatomic, getter = isAutomaticDismiss) BOOL automaticDismiss;

@end
