//
//  UIBarButtonItem+BlockAction.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 16/12/12.
//
//

#import "UIBarButtonItem+BlockAction.h"
#import <objc/runtime.h>

static const void *UIBarButtonItemBlockActionKey = &UIBarButtonItemBlockActionKey;

@implementation UIBarButtonItem (BlockAction)

- (void)setActionBlock:(void (^)(id))block {
	objc_setAssociatedObject(self, UIBarButtonItemBlockActionKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
	[self setTarget:self];
	[self setAction:@selector(_executeActionBlock:)];
}

- (void)_executeActionBlock:(id)sender {
	void (^block)(id) = objc_getAssociatedObject(self, UIBarButtonItemBlockActionKey);
	if (block) block(sender);
}

@end
