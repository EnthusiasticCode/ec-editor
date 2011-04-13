//
//  UIView+ConcurrentAnimation.m
//  ItemView
//
//  Created by Uri Baghin on 4/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIView+ConcurrentAnimation.h"


@implementation UIView (ConcurrentAnimation)

+ (void)animateConcurrentlyToAnimationsWithFlag:(BOOL *)animatingFlag duration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion;
{
    if (!*animatingFlag)
        [self animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:animations completion:^(BOOL finished) {
            if (finished)
                *animatingFlag = NO;
            if (completion)
                completion(finished);
        }];
    else
        [self animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:animations completion:^(BOOL finished) {
            if (finished)
                *animatingFlag = NO;
            if (completion)
                completion(finished);
        }];
    *animatingFlag = YES;
}

@end
