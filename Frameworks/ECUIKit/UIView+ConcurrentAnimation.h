//
//  UIView+ConcurrentAnimation.h
//  ItemView
//
//  Created by Uri Baghin on 4/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIView (ConcurrentAnimation)
+ (void)animateConcurrentlyToAnimationsWithFlag:(BOOL *)animatingFlag duration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion;
@end
