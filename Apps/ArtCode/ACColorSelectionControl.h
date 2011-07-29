//
//  ACColorSelectionControl.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACColorSelectionControl : UIControl

@property (nonatomic, strong) NSArray *colors;

@property (nonatomic, readonly) UIColor *selectedColor;

@property (nonatomic) CGFloat colorCellsMargin;

@property (nonatomic) NSUInteger columns;

@property (nonatomic) NSUInteger rows;

@property (nonatomic, weak) id userInfo;

@end
