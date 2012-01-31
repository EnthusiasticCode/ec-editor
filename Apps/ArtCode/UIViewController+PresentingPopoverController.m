//
//  UIViewController+ContainingPopoverController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIViewController+PresentingPopoverController.h"
#import <objc/runtime.h>

static const void *presentingPopoverControllerKey;

@implementation UIViewController (PresentingPopoverController)

- (UIPopoverController *)presentingPopoverController
{
    return objc_getAssociatedObject(self, &presentingPopoverControllerKey);
}

- (void)setPresentingPopoverController:(UIPopoverController *)popoverController
{
    objc_setAssociatedObject(self, &presentingPopoverControllerKey, popoverController, OBJC_ASSOCIATION_ASSIGN);
}

@end
