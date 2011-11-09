//
//  ECPopoverController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECBasePopoverView.h"


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

@property (nonatomic, readonly, strong) ECBasePopoverView *popoverView;

+ (Class)popoverViewClass;

#pragma mark Advanced Behaviours

/// Insets applied to the calculated allowed bounds to fit the popover view during presentation. Default 5 for all values.
@property (nonatomic) UIEdgeInsets allowedBoundsInsets;

/// If YES (default), the user will be able to dismiss the popover by tapping anyehere outside it and passthroughViews views.
@property (nonatomic, getter = isAutomaticDismiss) BOOL automaticDismiss;

@end


@interface ECTexturedPopoverController : ECPopoverController
@end