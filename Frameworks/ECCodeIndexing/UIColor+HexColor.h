//
//  UIColor+HexColor.h
//  ECCodeIndexing
//
//  Created by Nicola Peduzzi on 30/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HexColor)

+ (UIColor *)colorWithHexString:(NSString *)string;

@end