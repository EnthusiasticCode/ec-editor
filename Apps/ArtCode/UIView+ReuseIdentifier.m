//
//  UIView+ReuseIdentifier.m
//  ACUI
//
//  Created by Nicola Peduzzi on 30/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIView+ReuseIdentifier.h"
#import <objc/runtime.h>

static const char *reuseIdentifierAssociatedObjectKey = "viewReuseIdentifier";

@implementation UIView (UIView_ReuseIdentifier)

- (void)setReuseIdentifier:(NSString *)reuseIdentifier
{
  objc_setAssociatedObject(self, reuseIdentifierAssociatedObjectKey, reuseIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)reuseIdentifier
{
  return objc_getAssociatedObject(self, reuseIdentifierAssociatedObjectKey);
}

@end
