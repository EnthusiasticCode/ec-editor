//
//  ECStoryboardViewSegue.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    ECStoryboardSegueAnimationOptionEnterLeft = 1 << 0,
    ECStoryboardSegueAnimationOptionEnterRight = 2 << 0,
    ECStoryboardSegueAnimationOptionEnterTop = 3 << 0,
    ECStoryboardSegueAnimationOptionEnterBottom = 4 << 0,
    ECStoryboardSegueAnimationOptionExitLeft = 1 << 4,
    ECStoryboardSegueAnimationOptionExitRight = 2 << 4,
    ECStoryboardSegueAnimationOptionExitTop = 3 << 4,
    ECStoryboardSegueAnimationOptionExitBottom = 4 << 4,
} ECStoryboardSegueAnimationOptions;

@interface ECStoryboardSegue : UIStoryboardSegue
@property (nonatomic, strong) UIView *exitingView;
@property (nonatomic) ECStoryboardSegueAnimationOptions options; 
@end
