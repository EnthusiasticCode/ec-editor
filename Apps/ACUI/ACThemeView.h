//
//  ACThemeView.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACThemeView : UIView

@property (nonatomic, strong) UIColor *backgroundInternalColor;

@property (nonatomic, strong) UIColor *borderColor;

@property (nonatomic) UIEdgeInsets borderInsets;

@property (nonatomic) CGFloat cornerRadius;

@end
