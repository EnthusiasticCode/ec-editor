//
//  UIControl+BlockAction.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIControl (UIControl_BlockAction)

- (void)setActionBlock:(void(^)(id sender))block forControlEvent:(UIControlEvents)controlEvent;

@end
