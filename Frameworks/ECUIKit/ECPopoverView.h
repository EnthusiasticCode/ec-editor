//
//  ECPopoverView.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECPopoverView : UIView

#pragma mark Style

@property (nonatomic) CGFloat cornerRadius;

#pragma mark Content

@property (nonatomic) UIEdgeInsets contentInsets;

@property (nonatomic) CGSize contentSize;

@property (nonatomic, retain) UIView *contentView;

#pragma mark Arrow

@property (nonatomic) UIPopoverArrowDirection arrowDirection;

@property (nonatomic) CGFloat arrowPosition;

@property (nonatomic) CGFloat arrowSize;

@end
