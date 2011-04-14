//
//  ECPopoverView.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECPopoverView : UIView

@property (nonatomic) UIPopoverArrowDirection arrowDirection;

@property (nonatomic) CGFloat arrowPosition;

@property (nonatomic) CGFloat arrowSize;

@property (nonatomic, readonly) CGRect contentRect;

@end
