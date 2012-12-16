//
//  ColorSelectionControl.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorSelectionControl : UISegmentedControl

@property (nonatomic, strong) NSArray *colors;

@property (nonatomic, strong) UIColor *selectedColor;

@end
