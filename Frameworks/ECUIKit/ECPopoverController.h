//
//  ECPopoverController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECPopoverController : NSObject

- (id)initWithContentViewController:(UIViewController *)viewController;

@property (nonatomic, assign) id <UIPopoverControllerDelegate> delegate;

@property (nonatomic, retain) UIViewController *contentViewController;
- (void)setContentViewController:(UIViewController *)viewController animated:(BOOL)animated;

@property (nonatomic) CGSize popoverContentSize;
- (void)setPopoverContentSize:(CGSize)size animated:(BOOL)animated;

@property (nonatomic, readonly, getter=isPopoverVisible) BOOL popoverVisible;

@property (nonatomic, readonly) UIPopoverArrowDirection popoverArrowDirection;

@property (nonatomic, copy) NSArray *passthroughViews;

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

- (void)dismissPopoverAnimated:(BOOL)animated;

@end
