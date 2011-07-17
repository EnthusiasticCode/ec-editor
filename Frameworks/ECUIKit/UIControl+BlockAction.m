//
//  UIControl+BlockAction.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIControl+BlockAction.h"
#import <objc/runtime.h>

static const char *actionBlockKey = "actionBlock";

@implementation UIControl (UIControl_BlockAction)

+ (void)actionBlockAction:(id)sender
{
    void (^block)(id) = (void (^)(id))objc_getAssociatedObject(sender, actionBlockKey);
    if (block)
        block(sender);
}

- (void)setActionBlock:(void (^)(id))block forControlEvent:(UIControlEvents)controlEvent
{
    objc_setAssociatedObject(self, actionBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self addTarget:[UIControl class] action:@selector(actionBlockAction:) forControlEvents:controlEvent];
}

@end
