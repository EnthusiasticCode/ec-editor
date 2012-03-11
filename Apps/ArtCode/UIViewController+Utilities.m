//
//  UIViewController+ContainingPopoverController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIViewController+Utilities.h"
#import <objc/runtime.h>

static const void *_presentingPopoverControllerKey;
static const void *_rightBarButtonItemOriginal;

@implementation UIViewController (Utilities)

- (UIPopoverController *)presentingPopoverController
{
    return objc_getAssociatedObject(self, &_presentingPopoverControllerKey);
}

- (void)setPresentingPopoverController:(UIPopoverController *)popoverController
{
    objc_setAssociatedObject(self, &_presentingPopoverControllerKey, popoverController, OBJC_ASSOCIATION_ASSIGN);
}

- (void)startRightBarButtonItemActivityIndicator
{
    if(objc_getAssociatedObject(self, &_rightBarButtonItemOriginal))
        return;
    
    UIBarButtonItem *originalItem = self.navigationItem.rightBarButtonItem;
    objc_setAssociatedObject(self, &_rightBarButtonItemOriginal, originalItem ? originalItem : [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [activityIndicator startAnimating];
}

- (void)stopRightBarButtonItemActivityIndicator
{
    UIBarButtonItem *original = objc_getAssociatedObject(self, &_rightBarButtonItemOriginal);
    if (original)
    {
        objc_setAssociatedObject(self, &_rightBarButtonItemOriginal, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if ((NSNull *)original != [NSNull null])
            self.navigationItem.rightBarButtonItem = original;
        else
            self.navigationItem.rightBarButtonItem = nil;
    }
}

@end
